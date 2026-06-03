use std::ffi::OsString;
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::Command;

use anyhow::{Context, Result, anyhow, bail};
use chrono::{DateTime, Utc};
use clap::{Parser, Subcommand, ValueEnum};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

const STATE_VERSION: u32 = 1;

#[derive(Debug, Parser)]
#[command(name = "kytask")]
#[command(about = "User-led task planning for harness engineering.")]
pub struct Cli {
    #[arg(long, global = true, hide = true)]
    repo_root: Option<PathBuf>,

    #[arg(long, global = true)]
    state_dir: Option<PathBuf>,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Debug, Subcommand)]
enum Commands {
    /// Start a new active plan.
    Start {
        title: String,
        #[arg(long)]
        goal: String,
        #[arg(long = "user-action")]
        user_actions: Vec<String>,
        #[arg(long = "codex-action")]
        codex_actions: Vec<String>,
        #[arg(long = "shared-action")]
        shared_actions: Vec<String>,
        #[arg(long)]
        replace: bool,
    },
    /// Add a plan item.
    Add {
        #[arg(long, value_enum, default_value_t = Owner::Shared)]
        owner: Owner,
        text: String,
    },
    /// Mark a plan item completed.
    Check { item: String },
    /// Add a restartable note.
    Note {
        #[arg(long, value_enum, default_value_t = NoteKind::Current)]
        kind: NoteKind,
        text: String,
    },
    /// Show the active plan.
    Plan {
        #[arg(long)]
        json: bool,
    },
    /// Show a compact restart summary.
    Resume {
        #[arg(long)]
        json: bool,
    },
    /// Finish the active plan.
    Finish {
        #[arg(long)]
        summary: Option<String>,
        #[arg(long)]
        verification: Vec<String>,
        #[arg(long)]
        allow_open: bool,
    },
    /// List tasks.
    List {
        #[arg(long)]
        all: bool,
    },
}

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize, ValueEnum)]
#[serde(rename_all = "kebab-case")]
enum Owner {
    User,
    Codex,
    Shared,
}

impl Owner {
    fn label(self) -> &'static str {
        match self {
            Owner::User => "user",
            Owner::Codex => "codex",
            Owner::Shared => "shared",
        }
    }
}

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "kebab-case")]
enum TaskStatus {
    Active,
    Done,
    Replaced,
}

impl TaskStatus {
    fn label(self) -> &'static str {
        match self {
            TaskStatus::Active => "active",
            TaskStatus::Done => "done",
            TaskStatus::Replaced => "replaced",
        }
    }
}

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "kebab-case")]
enum ItemStatus {
    Pending,
    Done,
}

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize, ValueEnum)]
#[serde(rename_all = "kebab-case")]
enum NoteKind {
    Current,
    Decision,
    Risk,
    Next,
}

impl NoteKind {
    fn label(self) -> &'static str {
        match self {
            NoteKind::Current => "current",
            NoteKind::Decision => "decision",
            NoteKind::Risk => "risk",
            NoteKind::Next => "next",
        }
    }
}

#[derive(Debug, Deserialize, Serialize)]
struct State {
    version: u32,
    active_task_id: Option<Uuid>,
    tasks: Vec<Task>,
}

impl Default for State {
    fn default() -> Self {
        Self {
            version: STATE_VERSION,
            active_task_id: None,
            tasks: Vec::new(),
        }
    }
}

#[derive(Debug, Deserialize, Serialize)]
struct Task {
    id: Uuid,
    title: String,
    goal: String,
    branch: Option<String>,
    status: TaskStatus,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
    closed_at: Option<DateTime<Utc>>,
    items: Vec<Item>,
    notes: Vec<Note>,
    verification: Vec<String>,
    summary: Option<String>,
}

#[derive(Debug, Deserialize, Serialize)]
struct Item {
    text: String,
    owner: Owner,
    status: ItemStatus,
    completed_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Deserialize, Serialize)]
struct Note {
    kind: NoteKind,
    text: String,
    created_at: DateTime<Utc>,
}

pub fn run_from<I, T>(args: I, out: &mut dyn Write) -> Result<()>
where
    I: IntoIterator<Item = T>,
    T: Into<OsString> + Clone,
{
    let cli = Cli::parse_from(args);
    run(cli, out)
}

fn run(cli: Cli, out: &mut dyn Write) -> Result<()> {
    let repo_root = resolve_repo_root(cli.repo_root)?;
    let state_path = state_path(&repo_root, cli.state_dir.as_deref());
    let mut state = load_state(&state_path)?;

    match cli.command {
        Commands::Start {
            title,
            goal,
            user_actions,
            codex_actions,
            shared_actions,
            replace,
        } => {
            start_task(
                &mut state,
                &repo_root,
                title,
                goal,
                user_actions,
                codex_actions,
                shared_actions,
                replace,
            )?;
            save_state(&state_path, &state)?;
            writeln!(out, "Started task.")?;
            writeln!(out, "State: {}", state_path.display())?;
        }
        Commands::Add { owner, text } => {
            let task = active_task_mut(&mut state)?;
            task.items.push(new_item(text.clone(), owner));
            touch(task);
            save_state(&state_path, &state)?;
            writeln!(out, "Added {} item: {text}", owner.label())?;
        }
        Commands::Check { item } => {
            let task = active_task_mut(&mut state)?;
            let checked = check_item(task, &item)?;
            save_state(&state_path, &state)?;
            writeln!(out, "Checked item: {checked}")?;
        }
        Commands::Note { kind, text } => {
            let task = active_task_mut(&mut state)?;
            task.notes.push(Note {
                kind,
                text,
                created_at: Utc::now(),
            });
            touch(task);
            save_state(&state_path, &state)?;
            writeln!(out, "Added {} note.", kind.label())?;
        }
        Commands::Plan { json } => {
            let task = active_task(&state)?;
            write_plan(out, task, json, false)?;
        }
        Commands::Resume { json } => {
            let task = active_task(&state)?;
            write_plan(out, task, json, true)?;
        }
        Commands::Finish {
            summary,
            verification,
            allow_open,
        } => {
            finish_task(&mut state, summary, verification, allow_open)?;
            save_state(&state_path, &state)?;
            writeln!(out, "Finished task.")?;
        }
        Commands::List { all } => {
            write_list(out, &state, all)?;
        }
    }

    Ok(())
}

fn resolve_repo_root(repo_root: Option<PathBuf>) -> Result<PathBuf> {
    if let Some(path) = repo_root {
        return Ok(path);
    }

    let output = Command::new("git")
        .args(["rev-parse", "--show-toplevel"])
        .output();
    if let Ok(output) = output {
        if output.status.success() {
            let path = String::from_utf8(output.stdout)?.trim().to_owned();
            if !path.is_empty() {
                return Ok(PathBuf::from(path));
            }
        }
    }

    std::env::current_dir().context("failed to resolve current directory")
}

fn state_path(repo_root: &Path, state_dir: Option<&Path>) -> PathBuf {
    if let Some(state_dir) = state_dir {
        return state_dir.join("state.json");
    }
    let git_info = repo_root.join(".git").join("info");
    if git_info.is_dir() {
        return git_info.join("kyarameru-task").join("state.json");
    }
    repo_root.join(".kytask").join("state.json")
}

fn load_state(path: &Path) -> Result<State> {
    if !path.exists() {
        return Ok(State::default());
    }
    let content = fs::read_to_string(path)
        .with_context(|| format!("failed to read state: {}", path.display()))?;
    let state: State = serde_json::from_str(&content)
        .with_context(|| format!("failed to parse state: {}", path.display()))?;
    if state.version != STATE_VERSION {
        bail!(
            "unsupported state version: {} (expected {STATE_VERSION})",
            state.version
        );
    }
    Ok(state)
}

fn save_state(path: &Path, state: &State) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .with_context(|| format!("failed to create state directory: {}", parent.display()))?;
    }
    let content = serde_json::to_string_pretty(state)?;
    fs::write(path, format!("{content}\n"))
        .with_context(|| format!("failed to write state: {}", path.display()))
}

fn start_task(
    state: &mut State,
    repo_root: &Path,
    title: String,
    goal: String,
    user_actions: Vec<String>,
    codex_actions: Vec<String>,
    shared_actions: Vec<String>,
    replace: bool,
) -> Result<()> {
    let now = Utc::now();
    if let Some(task) = active_task_mut_optional(state) {
        if !replace {
            bail!("an active task already exists; use finish or start --replace");
        }
        task.status = TaskStatus::Replaced;
        task.closed_at = Some(now);
        task.updated_at = now;
        task.notes.push(Note {
            kind: NoteKind::Decision,
            text: "Replaced by a new active task.".to_string(),
            created_at: now,
        });
    }

    let mut items = Vec::new();
    items.extend(
        user_actions
            .into_iter()
            .map(|text| new_item(text, Owner::User)),
    );
    items.extend(
        codex_actions
            .into_iter()
            .map(|text| new_item(text, Owner::Codex)),
    );
    items.extend(
        shared_actions
            .into_iter()
            .map(|text| new_item(text, Owner::Shared)),
    );

    let task = Task {
        id: Uuid::new_v4(),
        title,
        goal,
        branch: current_branch(repo_root),
        status: TaskStatus::Active,
        created_at: now,
        updated_at: now,
        closed_at: None,
        items,
        notes: Vec::new(),
        verification: Vec::new(),
        summary: None,
    };
    state.active_task_id = Some(task.id);
    state.tasks.push(task);
    Ok(())
}

fn new_item(text: String, owner: Owner) -> Item {
    Item {
        text,
        owner,
        status: ItemStatus::Pending,
        completed_at: None,
    }
}

fn current_branch(repo_root: &Path) -> Option<String> {
    let output = Command::new("git")
        .args(["branch", "--show-current"])
        .current_dir(repo_root)
        .output()
        .ok()?;
    if !output.status.success() {
        return None;
    }
    let branch = String::from_utf8(output.stdout).ok()?.trim().to_owned();
    (!branch.is_empty()).then_some(branch)
}

fn active_task(state: &State) -> Result<&Task> {
    let id = state
        .active_task_id
        .ok_or_else(|| anyhow!("no active task; use start first"))?;
    state
        .tasks
        .iter()
        .find(|task| task.id == id)
        .ok_or_else(|| anyhow!("active task id is missing from state"))
}

fn active_task_mut(state: &mut State) -> Result<&mut Task> {
    active_task_mut_optional(state).ok_or_else(|| anyhow!("no active task; use start first"))
}

fn active_task_mut_optional(state: &mut State) -> Option<&mut Task> {
    let id = state.active_task_id?;
    state.tasks.iter_mut().find(|task| task.id == id)
}

fn touch(task: &mut Task) {
    task.updated_at = Utc::now();
}

fn check_item(task: &mut Task, target: &str) -> Result<String> {
    let index = if let Ok(number) = target.parse::<usize>() {
        if number == 0 || number > task.items.len() {
            bail!("item number out of range: {number}");
        }
        number - 1
    } else {
        let matches: Vec<usize> = task
            .items
            .iter()
            .enumerate()
            .filter_map(|(index, item)| (item.text == target).then_some(index))
            .collect();
        match matches.as_slice() {
            [index] => *index,
            [] => bail!("item not found: {target}"),
            _ => bail!("multiple items match; use item number"),
        }
    };

    let item = &mut task.items[index];
    item.status = ItemStatus::Done;
    item.completed_at = Some(Utc::now());
    let text = item.text.clone();
    touch(task);
    Ok(text)
}

fn finish_task(
    state: &mut State,
    summary: Option<String>,
    verification: Vec<String>,
    allow_open: bool,
) -> Result<()> {
    let task = active_task_mut(state)?;
    let open_items: Vec<&Item> = task
        .items
        .iter()
        .filter(|item| item.status != ItemStatus::Done)
        .collect();
    if !open_items.is_empty() && !allow_open {
        let names = open_items
            .iter()
            .map(|item| format!("- {}", item.text))
            .collect::<Vec<_>>()
            .join("\n");
        bail!("cannot finish with open items:\n{names}\nuse check or finish --allow-open");
    }
    let now = Utc::now();
    task.status = TaskStatus::Done;
    task.closed_at = Some(now);
    task.updated_at = now;
    task.summary = summary;
    task.verification = verification;
    state.active_task_id = None;
    Ok(())
}

fn write_plan(out: &mut dyn Write, task: &Task, json: bool, resume: bool) -> Result<()> {
    if json {
        let content = serde_json::to_string_pretty(task)?;
        writeln!(out, "{content}")?;
        return Ok(());
    }

    writeln!(
        out,
        "{}: {}",
        if resume { "Resume" } else { "Plan" },
        task.title
    )?;
    writeln!(out, "Goal: {}", task.goal)?;
    if let Some(branch) = &task.branch {
        writeln!(out, "Branch: {branch}")?;
    }
    writeln!(
        out,
        "Current: {}",
        latest_note(task, NoteKind::Current).unwrap_or("not recorded")
    )?;
    write_items(out, "User actions", task, Owner::User)?;
    write_items(out, "Codex support", task, Owner::Codex)?;
    write_items(out, "Shared work", task, Owner::Shared)?;
    writeln!(
        out,
        "Next: {}",
        latest_note(task, NoteKind::Next).unwrap_or("not recorded")
    )?;
    Ok(())
}

fn latest_note(task: &Task, kind: NoteKind) -> Option<&str> {
    task.notes
        .iter()
        .rev()
        .find(|note| note.kind == kind)
        .map(|note| note.text.as_str())
}

fn write_items(out: &mut dyn Write, label: &str, task: &Task, owner: Owner) -> Result<()> {
    writeln!(out, "{label}:")?;
    let mut count = 0;
    for (index, item) in task.items.iter().enumerate() {
        if item.owner != owner || item.status == ItemStatus::Done {
            continue;
        }
        count += 1;
        writeln!(out, "  {}. {}", index + 1, item.text)?;
    }
    if count == 0 {
        writeln!(out, "  none")?;
    }
    Ok(())
}

fn write_list(out: &mut dyn Write, state: &State, all: bool) -> Result<()> {
    let tasks: Vec<&Task> = state
        .tasks
        .iter()
        .filter(|task| all || task.status == TaskStatus::Active)
        .collect();
    if tasks.is_empty() {
        writeln!(out, "No tasks.")?;
        return Ok(());
    }
    for task in tasks {
        writeln!(out, "{}: {} {}", task.status.label(), task.id, task.title)?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use std::time::{SystemTime, UNIX_EPOCH};

    use super::*;

    fn temp_repo() -> PathBuf {
        let suffix = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        let root = std::env::temp_dir().join(format!("kytask-test-{suffix}"));
        fs::create_dir_all(root.join(".git").join("info")).unwrap();
        root
    }

    fn run(root: &Path, args: &[&str]) -> String {
        let mut full_args = vec![
            OsString::from("kytask"),
            OsString::from("--repo-root"),
            root.as_os_str().to_os_string(),
        ];
        full_args.extend(args.iter().map(OsString::from));
        let mut output = Vec::new();
        run_from(full_args, &mut output).unwrap();
        String::from_utf8(output).unwrap()
    }

    fn run_err(root: &Path, args: &[&str]) -> String {
        let mut full_args = vec![
            OsString::from("kytask"),
            OsString::from("--repo-root"),
            root.as_os_str().to_os_string(),
        ];
        full_args.extend(args.iter().map(OsString::from));
        let mut output = Vec::new();
        run_from(full_args, &mut output).unwrap_err().to_string()
    }

    #[test]
    fn start_and_plan_group_items_by_owner() {
        let root = temp_repo();

        run(
            &root,
            &[
                "start",
                "harness",
                "--goal",
                "user-led planning",
                "--user-action",
                "choose priority",
                "--codex-action",
                "prepare patch",
                "--shared-action",
                "review output",
            ],
        );
        let output = run(&root, &["plan"]);

        assert!(output.contains("Plan: harness"));
        assert!(output.contains("Goal: user-led planning"));
        assert!(output.contains("User actions:\n  1. choose priority"));
        assert!(output.contains("Codex support:\n  2. prepare patch"));
        assert!(output.contains("Shared work:\n  3. review output"));
    }

    #[test]
    fn note_check_and_resume() {
        let root = temp_repo();

        run(
            &root,
            &[
                "start",
                "task",
                "--goal",
                "finish",
                "--user-action",
                "decide",
            ],
        );
        run(&root, &["note", "--kind", "current", "design is stable"]);
        run(&root, &["note", "--kind", "next", "run tests"]);
        run(&root, &["add", "--owner", "codex", "implement"]);
        run(&root, &["check", "1"]);
        let output = run(&root, &["resume"]);

        assert!(output.contains("Resume: task"));
        assert!(output.contains("Current: design is stable"));
        assert!(output.contains("Codex support:\n  2. implement"));
        assert!(output.contains("Next: run tests"));
    }

    #[test]
    fn finish_refuses_open_items_unless_allowed() {
        let root = temp_repo();

        run(
            &root,
            &[
                "start",
                "task",
                "--goal",
                "finish",
                "--shared-action",
                "open",
            ],
        );
        let error = run_err(&root, &["finish"]);
        assert!(error.contains("cannot finish with open items"));

        run(
            &root,
            &["finish", "--allow-open", "--verification", "manual: ok"],
        );
        let output = run(&root, &["list"]);
        assert!(output.contains("No tasks."));
        let output = run(&root, &["list", "--all"]);
        assert!(output.contains("done:"));
    }

    #[test]
    fn start_replace_archives_current_task() {
        let root = temp_repo();

        run(&root, &["start", "first", "--goal", "one"]);
        let error = run_err(&root, &["start", "second", "--goal", "two"]);
        assert!(error.contains("an active task already exists"));

        run(&root, &["start", "second", "--goal", "two", "--replace"]);
        let output = run(&root, &["list", "--all"]);
        assert!(output.contains("replaced:"));
        assert!(output.contains("active:"));
    }
}

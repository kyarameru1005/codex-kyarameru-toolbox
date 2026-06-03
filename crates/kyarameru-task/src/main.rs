use std::io;

fn main() {
    if let Err(error) = kyarameru_task::run_from(std::env::args_os(), &mut io::stdout()) {
        eprintln!("error: {error}");
        std::process::exit(1);
    }
}

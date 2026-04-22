# 数学記法・LaTeX ガイド

## 集合論

| 記法 | LaTeX | 意味 |
|------|-------|------|
| $\in$ | `\in` | 属する |
| $\notin$ | `\notin` | 属さない |
| $\subset$ | `\subset` | 真部分集合 |
| $\subseteq$ | `\subseteq` | 部分集合 |
| $\cup$ | `\cup` | 和集合 |
| $\cap$ | `\cap` | 共通集合 |
| $\setminus$ | `\setminus` | 差集合 |
| $\emptyset$ | `\emptyset` | 空集合 |
| $\mathbb{N}, \mathbb{Z}, \mathbb{Q}, \mathbb{R}, \mathbb{C}$ | `\mathbb{N}` 等 | 数体系 |
| $|S|$ | `\|S\|` | 濃度 |
| $\mathcal{P}(S)$ | `\mathcal{P}(S)` | 冪集合 |

## 論理

| 記法 | LaTeX | 意味 |
|------|-------|------|
| $\land$ | `\land` | かつ（論理積） |
| $\lor$ | `\lor` | または（論理和） |
| $\neg$ | `\neg` | 否定 |
| $\implies$ | `\implies` | ならば |
| $\iff$ | `\iff` | 同値 |
| $\forall$ | `\forall` | 任意の |
| $\exists$ | `\exists` | 存在する |
| $\nexists$ | `\nexists` | 存在しない |

## 解析

| 記法 | LaTeX | 意味 |
|------|-------|------|
| $\lim_{x \to a}$ | `\lim_{x \to a}` | 極限 |
| $\sum_{i=1}^{n}$ | `\sum_{i=1}^{n}` | 総和 |
| $\prod_{i=1}^{n}$ | `\prod_{i=1}^{n}` | 総積 |
| $\int_a^b$ | `\int_a^b` | 積分 |
| $\frac{d}{dx}$ | `\frac{d}{dx}` | 微分 |
| $\partial$ | `\partial` | 偏微分 |
| $\infty$ | `\infty` | 無限大 |

## 代数

| 記法 | LaTeX | 意味 |
|------|-------|------|
| $\cong$ | `\cong` | 同型 |
| $\simeq$ | `\simeq` | 同値（ホモトピー等） |
| $\oplus$ | `\oplus` | 直和 |
| $\otimes$ | `\otimes` | テンソル積 |
| $\langle g \rangle$ | `\langle g \rangle` | 生成 |
| $[G:H]$ | `[G:H]` | 指数 |
| $\ker$ | `\ker` | 核 |
| $\operatorname{im}$ | `\operatorname{im}` | 像 |

## 定理環境（Markdown 記法）

```
**定義 1.1** ($X$ 上の位相).
集合 $X$ の部分集合族 $\mathcal{O}$ が...

**定理 1.2** (コンパクト性定理).
$X$ がコンパクトであるための必要十分条件は...

**証明.**
$X$ の任意の開被覆 $\{U_\alpha\}$ をとる...
∎

**補題 1.3**.
...

**系 1.4**.
定理 1.2 から直ちに...
```

## 証明記号

| 記号 | 用途 |
|------|------|
| ∎ (QED) | 証明終了 |
| ∵ | なぜなら |
| ∴ | ゆえに |
| := | 定義 |
| ≡ | 恒等的に等しい |

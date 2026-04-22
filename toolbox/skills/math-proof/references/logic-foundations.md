# 論理推論規則・形式体系

## 命題論理の推論規則

### 導入規則（Introduction）

| 規則 | 形式 | 説明 |
|------|------|------|
| $\land$-導入 | $P, Q \vdash P \land Q$ | 両方が真なら連言が真 |
| $\lor$-導入 | $P \vdash P \lor Q$ | 一方が真なら選言が真 |
| $\implies$-導入 | $[P] \vdash Q$ ならば $\vdash P \implies Q$ | 仮定 $P$ のもとで $Q$ が導ければ |
| $\neg$-導入 | $[P] \vdash \bot$ ならば $\vdash \neg P$ | 仮定から矛盾が導かれれば |

### 除去規則（Elimination）

| 規則 | 形式 | 説明 |
|------|------|------|
| $\land$-除去 | $P \land Q \vdash P$ (また $Q$) | 連言から各成分を取得 |
| $\lor$-除去 | $P \lor Q, [P] \vdash R, [Q] \vdash R$ ならば $R$ | 場合分け |
| $\implies$-除去 (MP) | $P, P \implies Q \vdash Q$ | モーダスポネンス |
| $\neg$-除去 | $\neg\neg P \vdash P$ | 二重否定除去（古典論理） |

## 述語論理の推論規則

| 規則 | 形式 | 説明 |
|------|------|------|
| $\forall$-導入 | 任意の $x$ で $P(x)$ → $\forall x: P(x)$ | $x$ に依存しない証明 |
| $\forall$-除去 | $\forall x: P(x)$ → $P(t)$ | 具体例への適用 |
| $\exists$-導入 | $P(t)$ → $\exists x: P(x)$ | 具体例から存在主張 |
| $\exists$-除去 | $\exists x: P(x), [P(c)] \vdash Q$ → $Q$ | 存在の仮定（$c$ は新規） |

## よく使う同値変換

| 名称 | 変換 |
|------|------|
| ド・モルガン | $\neg(P \land Q) \iff \neg P \lor \neg Q$ |
| ド・モルガン | $\neg(P \lor Q) \iff \neg P \land \neg Q$ |
| 対偶 | $(P \implies Q) \iff (\neg Q \implies \neg P)$ |
| 量化子交換 | $\neg\forall x: P(x) \iff \exists x: \neg P(x)$ |
| 量化子交換 | $\neg\exists x: P(x) \iff \forall x: \neg P(x)$ |
| 含意の書き換え | $(P \implies Q) \iff (\neg P \lor Q)$ |

## 形式体系

### ZFC 公理系（集合論）

1. **外延性**: 同じ元を持つ集合は等しい
2. **空集合**: 空集合が存在する
3. **対**: 任意の $a, b$ に対し $\{a, b\}$ が存在
4. **和集合**: $\bigcup S$ が存在
5. **冪集合**: $\mathcal{P}(S)$ が存在
6. **無限**: 無限集合が存在（自然数の存在）
7. **置換**: 関数の像は集合
8. **正則性**: $\in$ は整礎
9. **選択公理**: 選択関数が存在

### ペアノの公理（自然数）

1. $0$ は自然数
2. $n$ が自然数なら $S(n)$ も自然数
3. $S(n) = S(m) \implies n = m$（単射性）
4. $\forall n: S(n) \neq 0$（$0$ は後者でない）
5. **帰納法公理**: $P(0) \land (\forall k: P(k) \implies P(k+1)) \implies \forall n: P(n)$

## 論理的誤謬（証明で避けるべきもの）

| 誤謬 | 説明 | 例 |
|------|------|---|
| 前件肯定の誤り | $Q$ から $P$ を導く（$P \implies Q$ で） | 「雨なら地面が濡れる」から「地面が濡れていれば雨」 |
| 後件否定の混同 | $\neg P$ から $\neg Q$ を導く | 上記の裏 |
| 循環論法 | 証明したい命題を仮定に使う | $A$ の証明に $A$ を使う |
| 量化子の順序誤り | $\forall\exists$ と $\exists\forall$ の混同 | 一様連続 vs 各点連続 |
| 存在量化子の乱用 | $\exists$ で取った元を別の文脈で再利用 | 一つの $x$ を異なる条件で使う |

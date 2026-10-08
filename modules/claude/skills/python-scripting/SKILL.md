---
name: python-scripting
description: Pythonスクリプト・小規模Pythonプロジェクトを作成・修正・レビューする際の規約。シンプルでモダン、可読性の高いコードを目標とし、uvによる環境管理、strによるパス管理、pandasによるCSV入出力、numpy/pandasによるデータ配列、matplotlibスタイル `cudo-paper` による描画を定める。トリガー：Pythonコードを書く・直す・リファクタする・レビューする、.pyファイル、uv、pandas、numpy、matplotlib、グラフ・図の作成、CSV処理、データ解析スクリプト、数値計算スクリプトなど、Pythonを書くあらゆる場面。
---

# Python Scripting

ゴールは**シンプル・モダン・可読性**。判断に迷ったら次の優先順位に従う。

1. 正しさ
2. 読みやすさ（初見の人が上から読んで理解できるか）
3. 変更のしやすさ
4. 性能（明確に必要なときだけ）

既存の安定したコードを、この規約に合わせるためだけに書き換えない。新規コードと、今回触る箇所に適用する。

## 1. 構造：適切な粒度に切り分ける

- 1関数は1つの仕事だけをする。名前に "and" が入りそうなら分割する。目安は30行以内。
- スクリプトは「定数 → 関数 → `main()` → `if __name__ == "__main__":`」の順で上から読める構成にする。
- 処理は「読み込み → 計算 → 出力（保存・描画）」の段階ごとに関数を分ける。計算関数では入出力（I/O）をしない。
- 状態と振る舞いがまとまるときだけクラスにする。データの入れ物には `@dataclass` を使う。継承は避ける。
- 1ファイルで300行を超えたら、モジュールへの分割を検討する。

```python
def main() -> None:
    raw = load_measurements(INPUT_CSV)
    result = compute_flame_speed(raw)
    save_result(result, OUTPUT_CSV)
    plot_flame_speed(result, FIGURE_BASENAME)


if __name__ == "__main__":
    main()
```

## 2. 単体で理解できる関数・クラス

- 名前は略さない（`temperature`、`pressure`）。単位がある量は、名前か docstring に単位を書く。
- 型ヒントは必須で、モダンな記法を使う（`list[str]`、`X | None`。`Optional` / `List` は使わない）。
- 公開する関数には docstring を書く。1行目に要約を書き、必要に応じて引数・戻り値の**単位・shape・列名**を書く。
- 定数はファイル冒頭に `UPPER_SNAKE_CASE` で置き、根拠や単位をコメントで添える（理由の分からないマジックナンバーを残さない）。
- 設定用の引数は keyword-only（`*` の後ろ）にする。`True, False` が並ぶような真偽値フラグの代わりに `Literal["linear", "log"]` を使う。
- コメントには「何をしているか」ではなく「なぜそうするか」を書く。

```python
EXPANSION_RATIO_LIMIT = 10.0  # above this, the 1D assumption breaks down


def compute_laminar_flame_speed(
    df: pd.DataFrame,
    *,
    method: Literal["slope", "fit"] = "slope",
) -> pd.Series:
    """Compute laminar flame speed for each condition.

    Args:
        df: Columns "time_s" and "radius_m", one row per frame.
        method: How to derive dr/dt.

    Returns:
        Flame speed [m/s], indexed like ``df``.
    """
```

## 3. 愚直でわかりやすい実装

- 複雑なワンライナーより、名前の付いた中間変数と素直な for 文を選ぶ。
- 内包表記は「1つの変換と、あっても1つの条件」まで。ネストした内包表記、`lambda` の多段、`map` / `filter` の連鎖は書かない。
- メソッドチェーンは3〜4段までにする。それ以上は中間変数に分ける。
- 早期 return でネストを浅くする（3段以内）。
- 引数のデフォルト値に可変オブジェクトを使わない（`def f(x=[])` は禁止。`None` を受けて関数内で生成する）。
- 1つの関数は「入力を変更する」か「新しい値を返す」のどちらか一方に限る。numpy で事前確保した配列への代入は、関数内で閉じていれば問題ない。
- エラー処理はエラーメッセージに任せ、スクリプトでエラーメッセージを出力させない。

```python
# Bad: dense one-liner
peaks = {k: max(v, key=lambda r: r[1])[0] for k, v in groupby(sorted(rows), key=itemgetter(0))}

# Good: plain and explicit
peaks = {}
for case_name, group in df.groupby("case"):
    peak_row = group.loc[group["heat_release_w"].idxmax()]
    peaks[case_name] = peak_row["time_s"]
```

## 4. エラー処理

- 捕まえるのは処理できる例外だけで、型を具体的に指定する。bare `except:` や、`except Exception: pass` で握りつぶすことはしない。
- 例外を変換して投げ直すときは `raise NewError(...) from err` で原因を残す。
- 入力の検証は境界（ファイル読み込み直後・CLI 引数）で1回だけ行う。内部で同じ検証を繰り返さない。
- `assert` は実行時の検証に使わない（`-O` オプションで消えるため）。

## 5. 環境管理：uv

- `pip` や `venv` を直接使わない。実行は常に `uv run` で行う。
- **単一ファイルのスクリプト**：PEP 723 のインラインメタデータを書く。依存の追加は `uv add --script <file> <pkg>` で行う。

  ```python
  # /// script
  # requires-python = ">=3.12"
  # dependencies = ["numpy>=2", "pandas>=2", "matplotlib>=3.8"]
  # ///
  ```

  実行は `uv run script.py` で行う。

- **複数ファイルのプロジェクト**：`uv init` → `uv add <pkg>` → `uv run main.py` の順で進める。`pyproject.toml` と `uv.lock` をコミットする。
- 整形と lint は `uvx ruff format .` と `uvx ruff check .` で行う。

## 6. パスは str で扱う

- `pathlib.Path` を使わない。パスは `str` で保持し、`os.path` / `os` / `glob` で操作する。
- 結合は `os.path.join`、存在確認は `os.path.exists`、ディレクトリ作成は `os.makedirs(dir_name, exist_ok=True)` を使う。

```python
OUTPUT_DIR = "results"

csv_files = sorted(glob.glob(os.path.join(DATA_DIR, "*.csv")))
os.makedirs(OUTPUT_DIR, exist_ok=True)
output_csv = os.path.join(OUTPUT_DIR, "summary.csv")
```

## 7. データ：CSV は pandas、配列は ndarray / DataFrame / Series

- CSV の読み書きは `pd.read_csv` / `DataFrame.to_csv(index=False)` に統一する。`csv` モジュールや、`open()` での手書きの CSV 出力は使わない。
- 列名には単位を含める（`"temperature_K"`、`"pressure_Pa"`）。
- 数値配列は `np.ndarray`、表形式のデータは `pd.DataFrame`、1次元のラベル付きデータは `pd.Series` で持つ。Python の `list` は数値計算に使わない。
- 計算はベクトル化して書く。`df.iterrows()` や、要素ごとの Python ループは避ける。ただし逐次的な外部計算（ソルバ呼び出しなど）のループは素直に書いてよい。
- ループで結果を集めるときは、`list` に `dict` を溜めて最後に `pd.DataFrame(records)` にする（ループ内での `pd.concat` は使わない）。

```python
records = []
for temperature_k in np.linspace(800.0, 2000.0, 100):
    delay_s = compute_ignition_delay(temperature_k, PRESSURE_PA)
    records.append({"temperature_K": temperature_k, "ignition_delay_s": delay_s})

result = pd.DataFrame(records)
result.to_csv(OUTPUT_CSV, index=False)
```

## 8. 描画：matplotlib スタイル `cudo-paper`

home-manager が `cudo-paper.mplstyle` を `stylelib/` に配置している。このスタイルにはフォント、目盛り、CUDO カラーサイクル、図のサイズ（幅 90 mm、4:3）、constrained_layout、保存時の dpi と透過の設定が入っている。**rcParams を手書きしない。**

- 冒頭で `plt.style.use("cudo-paper")` を1回呼ぶ。
- 色は CUDO カラーサイクルを使い、明示するときは `"C0"`（赤）、`"C1"`（青）、`"C2"`（緑）、`"C3"`（紫）、`"C4"`（橙）… で指定する。
- オブジェクト指向 API（`fig, ax = plt.subplots()`）を使う。`plt.plot` は使わない。
- 軸ラベルには単位を付ける（`"Temperature (K)"`）。
- 描画関数は「DataFrame とファイル名の stem を受け取って保存する」形にする。保存は png / pdf / svg の3形式で行う。

```python
import matplotlib.pyplot as plt

plt.style.use("cudo-paper")

FIGURE_FORMATS = ("png", "pdf", "svg")


def save_figure(fig: plt.Figure, basename: str) -> None:
    """Save a figure in all formats used for papers and slides."""
    for ext in FIGURE_FORMATS:
        fig.savefig(f"{basename}.{ext}")


def plot_ignition_delay(result: pd.DataFrame, basename: str) -> None:
    fig, ax = plt.subplots()
    ax.plot(1000.0 / result["temperature_K"], result["ignition_delay_s"], marker="o")
    ax.set_yscale("log")
    ax.set_xlabel("1000/T (1/K)")
    ax.set_ylabel("Ignition delay time (s)")
    save_figure(fig, basename)
    plt.close(fig)
```

## 9. 書き終えたらチェック

```
- [ ] main() から順に読めば、処理の流れが分かる
- [ ] 各関数が名前・型ヒント・docstring だけで理解できる
- [ ] 複雑なワンライナー・深いネスト・理由の分からない定数がない
- [ ] パスは str、CSV は pandas、数値は ndarray / DataFrame / Series
- [ ] 図は plt.style.use("cudo-paper") で描いている
- [ ] PEP 723 のメタデータ、または pyproject.toml に依存が書かれていて、uv run で動く
- [ ] uvx ruff format / uvx ruff check が通る
```

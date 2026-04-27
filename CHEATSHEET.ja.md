# RuVJ チートシート

## 究極のチートシート

```ruby
# shapes
Bg(color:)
Circle(x: 0, y: 0, r: 1, color:, z: 0, steps: 16)
Rect(x: 0, y: 0, w: 1, h: 1, color:, z: 0)
Triangle(x: 0, y: 0, size: 1, angle: 0, color:, z: 0)
Line(x1: 0, y1: 0, x2: 1, y2: 0, color:, z: 0, bold: 0)
Text("str", x: 0, y: 0, size: 1, color:, align_x: :left, align_y: :middle, z: 0)
Ruby(x: 0, y: 0, size: 1, color:, z: 0, gap: 0.08)

# effects
Kaleidoscope(segments: 6) { ... }
Lissajous(a: 3, b: 2, delta: 0, rx: 5, ry: 5, steps: 128, bold: 0, color:, z: 0)
Ring(x: 0, y: 0, r: 1, color:, z: 0, steps: 32)
Tunnel(n: 10, offset: 0, r_max: 10, color:, z: 0)
Spectrum(n: 32, x: 0, y: -8, width: 24, height: 6, hue: 200, sat: 0.8, val: 1.0, alpha: 255, gap: 0.1, z: 0)

# stateful (@@var ||= new → per-frame)
Warp.new(max: 300)
Warp#step(r_min: 2, density: 5, speed: 0.05, accel: 1.04, bold: 0, color:, z: 0)
Particles.new(max: 300)
Particles#emit(x: 0, y: 0, speed: 0.15, life: 90, hue: 0, size: 0.2, n: 1)
Particles#update
Particles#draw(z: 0)
Trail.new(len: 60)
Trail#update { ... }
Ripple.new(max: 20, speed: 0.2, life: 60, r_start: 0.5)
Ripple#update(emit: false) { |r:, alpha:| ... }

# helpers
polar(r, theta) #=> {x:, y:}
```

各APIの詳細は以降のセクションを参照。

---

## 座標系

```
         y = +9
          ↑
-16 ←────┼────→ +16  (x)
          ↓
         y = -9
```

- 画面中央が原点 `(0, 0)`
- 1ユニット = 40px
- **y は上向き**（数学座標系）

---

## color オブジェクト

```ruby
{h: 色相, s: 彩度, v: 明度}          # a 省略時は不透明 (255)
{h: 色相, s: 彩度, v: 明度, a: 透明度}
```

| キー | 型    | 範囲       | デフォルト |
|------|-------|-----------|-----------|
| `h`  | Float | `0..360`  | `0`（赤）  |
| `s`  | Float | `0.0..1.0`| `1`       |
| `v`  | Float | `0.0..1.0`| `1`       |
| `a`  | Int   | `0..255`  | `255`     |

**よく使う色相**

| h | 色 |
|---|---|
| 0 / 360 | 赤 |
| 30 | オレンジ |
| 60 | 黄 |
| 120 | 緑 |
| 180 | シアン |
| 200 | 水色 |
| 240 | 青 |
| 280 | 紫 |
| 300 | マゼンタ |

---

## @vj — オーディオ・ビートコンテキスト

### 音量・周波数帯域（0.0〜1.0、ピーク追従で正規化済み）

| メソッド | 内容 |
|---------|------|
| `@vj.amp` | 全体音量 |
| `@vj.low` | 低域（ベース・キック） |
| `@vj.mid` | 中域（ボーカル・コード） |
| `@vj.hi`  | 高域（ハット・シンバル） |

### ビート

| メソッド | 型 | 内容 |
|---------|-----|------|
| `@vj.beat?` | Bool | そのフレームでビートが発火したら `true`（1回限り消費） |
| `@vj.beat`  | Float | `0..360`  | ビート直後 1.0 → 指数減衰。フラッシュや弾性に |
| `@vj.phase` | Float | `0.0..1.0` | BPMに同期した位相。1周 = 1ビート |
| `@vj.bpm`   | Float | タップテンポ / 手動設定の BPM |
| `@vj.count` | Int   | ビート通算カウント |

### 時間・フレーム

| メソッド | 型 | 内容 |
|---------|-----|------|
| `@vj.t`     | Float | 起動からの経過秒 |
| `@vj.frame` | Int   | 描画フレーム数 |

### スペクトラム・波形

| メソッド | 型 | 内容 |
|---------|-----|------|
| `@vj.spectrum(n=32)` | `Array<Float>` | 対数スケール n 本のスペクトラム（各 0.0〜1.0） |
| `@vj.waveform`       | `Array<Float>` | 256 点の波形データ（各 -1.0〜1.0 程度） |

### OSC（MIDI CC 連携）

```ruby
@vj.osc('/midi/cc/1')   # 0.0〜1.0。未受信なら 0.0
```

---

## VjShapes — プリミティブ

### Bg — 背景塗り

```ruby
Bg(color:)
```

### Circle — 塗りつぶし円

```ruby
Circle(x: 0, y: 0, r: 1, color:, z: 0, steps: 16)
```

| 引数 | 範囲 | 内容 |
|------|------|------|
| `r`  | `> 0` | 半径（VJ単位） |
| `steps` | 推奨 8〜32 | 分割数。大きいほど滑らか |

### Rect — 矩形

```ruby
Rect(x: 0, y: 0, w: 1, h: 1, color:, z: 0)
```

### Triangle — 正三角形

```ruby
Triangle(x: 0, y: 0, size: 1, angle: 0, color:, z: 0)
```

| 引数 | 単位 | 内容 |
|------|------|------|
| `angle` | ラジアン | 回転角 |

### Line — 線分

```ruby
Line(x1: 0, y1: 0, x2: 1, y2: 0, color:, z: 0, bold: 0)
```

| 引数 | 範囲 | 内容 |
|------|------|------|
| `bold` | `0..` | 0 = 細線、正値 = 線幅（1/100 VJ単位。`bold: 100` で幅 1） |

### Text — テキスト

```ruby
Text("hello", x: 0, y: 0, size: 1, color:, align_x: :left, align_y: :middle, z: 0)
```

| 引数 | 選択肢 | 内容 |
|------|--------|------|
| `align_x` | `:left` `:center` `:right` | 水平揃え |
| `align_y` | `:top` `:middle` `:bottom`  | 垂直揃え |

改行 `\n` で複数行対応。

### Ruby — Rubyロゴ風のジェム

```ruby
Ruby(x: 0, y: 0, size: 1, color:, z: 0, gap: 0.08)
```

塗りつぶされた8枚の三角形（パビリオン3枚 = 左右狭 + 中央ワイド、クラウン5枚 = upward 3枚 + downward 2枚のジグザグ）で Ruby ロゴの輪郭を構成。赤（`{h: 0, s: 1, v: 1}`）で描画するとまさにロゴそのもの。`gap` を大きくするとファセット間の白い隙間が広がってシャープな宝石感が出る（0 で隙間なしのベタ塗りポリゴン）。

| 引数 | デフォルト | 内容 |
|------|-----------|------|
| `size` | `1` | 全体のスケール（幅は約 `2 * size` VJ単位、高さは約 `1.2 * size` VJ単位） |
| `gap`  | `0.08` | 各ファセット三角形を重心方向に縮める割合（0.0〜1.0） |

---

## VjShapes — 複合エフェクト

### Kaleidoscope — 回転対称描画

```ruby
Kaleidoscope(segments: 6) do
  Circle(x: 3, y: 0, r: @vj.mid * 2, color: {h: 120, s: 1, v: 1})
end
```

ブロック内の描画を `segments` 回均等回転して複製。`@vj` や他のシェイプメソッドはブロック内で直接使える。

### Lissajous — リサージュ曲線

```ruby
Lissajous(a: 3, b: 2, delta: 0, rx: 5, ry: 5, steps: 128, bold: 0, color:, z: 0)
```

| 引数 | 内容 |
|------|------|
| `a`, `b` | X/Y 周波数比。整数比で閉じた曲線（例: 3:2, 5:4） |
| `delta` | 位相差（ラジアン）。`@vj.t * 0.5` でアニメーション |
| `rx`, `ry` | X/Y 半径（VJ単位） |
| `bold` | Line の太さ（`Line` の `bold` と同じ単位） |

### Ring — 中空円

```ruby
Ring(x: 0, y: 0, r: 3, color:, z: 0, steps: 32)
```

`Circle` の中空版。`Line` の折れ線で円周を描く。

| 引数 | デフォルト | 内容 |
|------|-----------|------|
| `r`     | `1`  | 半径（VJ単位） |
| `steps` | `32` | 分割数 |

### Tunnel — 同心リングトンネル

```ruby
Tunnel(n: 10, offset: 0, r_max: 10, color:, z: 0)
```

| 引数 | デフォルト | 内容 |
|------|-----------|------|
| `n`      | `10` | リング数 |
| `offset` | `0`  | 位相オフセット（0.0〜1.0）。`@vj.t * 0.3` でスクロール |
| `r_max`  | `10` | 最大半径（VJ単位） |

alpha は中心 0 → 外側 255 で自動グラデーション（`color` の `a:` 指定不要）。

---

## Warp — 放射ワープストリーム

```ruby
@@warp ||= Warp.new(max: 300)

def draw_scene
  @@warp.step(r_min: 2, density: 5, color: {h: 200, s: 1, v: 1})
end
```

| 引数 | デフォルト | 内容 |
|------|-----------|------|
| `r_min`   | `2`    | デッドゾーン半径（VJ単位）。この内側は無描画 |
| `density` | `5`    | 1フレームあたりの放出数 |
| `speed`   | `0.05` | 初速（VJ単位/フレーム） |
| `accel`   | `1.04` | 速度倍率。`1.0` = 等速、`1.04〜1.08` でワープ感 |
| `bold`    | `0`    | ストリーク線の太さ（`Line` と同じ単位） |
| `max`     | `300`  | `new` 時に指定。最大パーティクル数 |

- `r_prev → r` の Line ストリークで放射線を描画
- alpha は距離に比例して自動計算（`color` の `a:` は上書きされる）

---

## VjEffects::Spectrum — スペクトラムバー

```ruby
require_relative 'lib/vj_effects/spectrum'
include VjEffects::Spectrum

def draw_scene
  Spectrum(n: 32, x: 0, y: -8, width: 24, height: 6, hue: 0..360)
end
```

| 引数 | デフォルト | 内容 |
|------|-----------|------|
| `n`      | `32`  | バー数（`@vj.spectrum(n)` に渡る） |
| `x`, `y` | `0, -8` | 左端の X 位置、バー群の下端 Y 位置 |
| `width`  | `24`  | 全体幅（VJ単位） |
| `height` | `6`   | 最大高さ（VJ単位） |
| `hue`    | `0..360` | 色相。数値で全 bar 同色、Range で `begin..end` を `n` 分割して各 bar に割り当て（`0..360` でレインボー） |
| `sat`    | `0.8` | 彩度 |
| `val`    | `1.0` | 明度 |
| `alpha`  | `255` | 不透明度 |
| `gap`    | `0.1` | バー間の隙間（VJ単位） |

---

## Particles — 重力パーティクル

```ruby
@@ps ||= Particles.new(max: 500)

def draw_scene
  @@ps.emit(x: 0, y: 0, speed: 0.2, life: 120, hue: @vj.t * 30 % 360, n: @vj.beat? ? 20 : 2)
  @@ps.update
  @@ps.draw(z: 1)
end
```

### emit 引数

| 引数 | デフォルト | 内容 |
|------|-----------|------|
| `x`, `y` | `0, 0` | 放出位置（VJ単位） |
| `speed`  | `0.15` | 最大初速（実際は 0〜speed のランダム） |
| `life`   | `90`   | 寿命（フレーム数） |
| `hue`    | `0`    | 色相（0〜360） |
| `size`   | `0.2`  | 半径（VJ単位） |
| `n`      | `1`    | 1回の emit 数 |

- 重力: `vy -= 0.003` / フレーム（下方向）
- alpha は `life / max_life` で寿命に比例して減衰
- `@@` クラス変数でホットリロード後も状態を保持

---

## Trail — 残像トレイル

```ruby
@@trail ||= Trail.new(len: 60)

def draw_scene
  Bg(color: {h: 0, s: 0, v: 0})
  @@trail.update do
    Circle(x: Math.sin(@vj.t * 2) * 10, y: 0, r: 0.5, color: {h: 180, s: 1, v: 1})
  end
end
```

ブロック内の描画を毎フレーム記録し、直近 `len` フレーム分を alpha fade させながら再生。ブロック内の `@vj` や `Circle/Ring/Line` 等は呼び出し側 (`RuVJ`) コンテキストで解決される。

| 引数 | デフォルト | 内容 |
|------|-----------|------|
| `len` | `60` | 保持するフレーム数。大きいほど残像が長く尾を引く |

- Gosu は毎フレーム画面を clear するため、半透明 `Bg` で残像を作る手法は使えない。本エフェクトで代替する
- ブロック内の `translate/scale/rotate` は記録時点で座標に焼き込まれる (`Kaleidoscope` をネストすると各フレームで静止した万華鏡が残像する挙動)

---

## Ripple — 波紋エフェクト

```ruby
@@ripple ||= Ripple.new(max: 20, speed: 0.2, life: 60)

def draw_scene
  Bg(color: {h: 0, s: 0, v: 0.02})
  @@ripple.update(emit: @vj.beat?) do |r:, alpha:|
    Ring(x: 0, y: 0, r: r, color: {h: 180, s: 1, v: 1, a: alpha})
  end
end
```

`emit: true` のフレームで新しい波紋 (drop) を発生させ、フレームごとに `speed` だけ半径を広げながら `life` フレーム後に消える。毎フレーム、生きている全 drop についてブロックを呼び出し、`r` と `alpha` をキーワード引数で渡す。

### Ripple.new 引数

| 引数 | デフォルト | 内容 |
|------|-----------|------|
| `max`     | `20`  | 同時に存在できる drop 数。超過時は emit 抑制 |
| `speed`   | `0.2` | フレームあたり半径が増える量 (VJ単位) |
| `life`    | `60`  | drop の寿命 (フレーム数) |
| `r_start` | `0.5` | 発生時の初期半径 (VJ単位) |

### update 引数

| 引数 | デフォルト | 内容 |
|------|-----------|------|
| `emit` | `false` | `true` のフレームで新規 drop を発生 |

### ブロック引数 (キーワード)

| キー | 型 | 内容 |
|------|-----|------|
| `r`     | Float | 現在の半径 (VJ単位) |
| `alpha` | Int   | `0..255`、寿命に比例して減衰 |

---

## polar — 極座標ヘルパー

```ruby
polar(r, theta)  # => {x:, y:}

# Circle への展開例
Circle(**polar(3, @vj.t), r: 1, color: {h: 0, s: 1, v: 1})
```

| 引数 | 単位 |
|------|------|
| `r`     | VJ単位 |
| `theta` | ラジアン |

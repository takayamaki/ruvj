require_relative 'vj_shapes'
require_relative 'renderer/base'

class WarpStream
  include VjShapes

  # 画面対角線より少し大きい値（VJ座標系）
  MAX_R = Math.sqrt(16.0**2 + 9.0**2) + 1  # ≈ 19.4

  Particle = Struct.new(:angle, :r, :r_prev, :speed)

  def initialize(max: 300)
    @particles = []
    @max = max
  end

  # emit・update・drawを一括実行。visual.rb の draw_scene から呼ぶ。
  #
  # visual.rb 使用例:
  #   @@warp ||= WarpStream.new(max: 300)
  #   def draw_scene
  #     @@warp.step(r_min: 2, density: 5, bold: 10, color: [200, 1, 1])
  #   end
  #
  # r_min:   デッドゾーン半径（VJ座標ユニット）。この内側は無描画
  # density: 1フレームあたりの放出数
  # speed:   初速（VJ座標ユニット/フレーム）
  # accel:   フレームごとの速度倍率（1.0超で加速、ワープ感が増す）
  # bold:    ストリーク線の太さ（1/100 VJユニット）。0で細線、正の値でquad描画
  # color:   [h, s, v] または [h, s, v, a]
  def step(r_min: 2, density: 5, speed: 0.05, accel: 1.04, bold: 0, color:, z: 0)
    emit(r_min: r_min, density: density, speed: speed)
    update(accel: accel)
    draw(r_min: r_min, color: color, z: z, bold: bold)
    @particles.reject! { |p| p.r > MAX_R }
  end

  private

  def emit(r_min:, density:, speed:)
    density.times do
      break if @particles.size >= @max
      s = speed * (0.5 + rand * 0.5)
      @particles << Particle.new(rand * Math::PI * 2, r_min.to_f, r_min.to_f, s)
    end
  end

  def update(accel:)
    @particles.each do |p|
      p.r_prev = p.r
      p.r     += p.speed
      p.speed *= accel
    end
  end

  def draw(r_min:, color:, z:, bold:)
    h, s, v = color[0], color[1], color[2]
    @particles.each do |p|
      next if p.r <= r_min
      x1 = Math.cos(p.angle) * [p.r_prev, r_min].max
      y1 = Math.sin(p.angle) * [p.r_prev, r_min].max
      x2 = Math.cos(p.angle) * p.r
      y2 = Math.sin(p.angle) * p.r
      alpha = ((p.r / MAX_R) * 255).clamp(0, 255).to_i
      Line(x1: x1, y1: y1, x2: x2, y2: y2, color: [h, s, v, alpha], z: z, bold: bold)
    end
  end
end

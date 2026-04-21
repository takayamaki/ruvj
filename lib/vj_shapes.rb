require_relative 'renderer/base'

module VjShapes
  W    = 1280
  H    = 720
  UNIT = 40.0

  def vj_px(x, y)
    [W / 2.0 + x * UNIT, H / 2.0 - y * UNIT]
  end

  def Circle(x: 0, y: 0, r: 1, color:, z: 0, steps: 16)
    cx, cy = vj_px(x, y)
    pr = r * UNIT
    c  = hsv_to_color(color)
    steps.times do |i|
      a1 = i     * Math::PI * 2 / steps
      a2 = (i+1) * Math::PI * 2 / steps
      VjRenderer.current.draw_triangle(
        cx,                     cy,                     c,
        cx + Math.cos(a1) * pr, cy - Math.sin(a1) * pr, c,
        cx + Math.cos(a2) * pr, cy - Math.sin(a2) * pr, c,
        z
      )
    end
  end

  def Rect(x: 0, y: 0, w: 1, h: 1, color:, z: 0)
    px, py = vj_px(x, y)
    pw, ph = w * UNIT, h * UNIT
    VjRenderer.current.draw_rect(px - pw / 2, py - ph / 2, pw, ph, hsv_to_color(color), z)
  end

  def Triangle(x: 0, y: 0, size: 1, angle: 0, color:, z: 0)
    cx, cy = vj_px(x, y)
    r = size * UNIT
    c = hsv_to_color(color)
    3.times do |i|
      a1 = i       * Math::PI * 2 / 3 + angle
      a2 = (i + 1) * Math::PI * 2 / 3 + angle
      VjRenderer.current.draw_triangle(
        cx,                    cy,                    c,
        cx + Math.cos(a1) * r, cy - Math.sin(a1) * r, c,
        cx + Math.cos(a2) * r, cy - Math.sin(a2) * r, c,
        z
      )
    end
  end

  # bold: 線の太さ。単位は 1/100 VJユニット（bold: 100 で 1VJユニット幅）。
  #       0 で Gosu.draw_line を使う細線、正値で三角形2枚のquad描画。
  def Line(x1: 0, y1: 0, x2: 1, y2: 0, color:, z: 0, bold: 0)
    px1, py1 = vj_px(x1, y1)
    px2, py2 = vj_px(x2, y2)
    c = hsv_to_color(color)
    if bold > 0
      dx, dy = px2 - px1, py2 - py1
      len = Math.hypot(dx, dy)
      return if len == 0
      half = bold * UNIT / 200.0
      ox, oy = -dy / len * half, dx / len * half
      r = VjRenderer.current
      r.draw_triangle(px1 - ox, py1 - oy, c, px1 + ox, py1 + oy, c, px2 + ox, py2 + oy, c, z)
      r.draw_triangle(px1 - ox, py1 - oy, c, px2 + ox, py2 + oy, c, px2 - ox, py2 - oy, c, z)
    else
      VjRenderer.current.draw_line(px1, py1, c, px2, py2, c, z)
    end
  end

  def Bg(color:)
    VjRenderer.current.draw_rect(0, 0, W, H, hsv_to_color(color), 0)
  end

  # visual.rb 使用例:
  #   Kaleidoscope(segments: 6) do
  #     Circle(x: 3, y: 0, r: @vj.mid * 2, color: {h: 120, s: 1, v: 1})
  #   end
  def Kaleidoscope(segments: 6, &block)
    segments.times do |i|
      angle = i * 360.0 / segments
      VjRenderer.current.rotate(angle) { instance_eval(&block) }
    end
  end

  # visual.rb 使用例:
  #   Lissajous(a: 3, b: 2, delta: @vj.t * 0.5, rx: @vj.mid * 6 + 2, ry: 3, bold: 10, color: {h: 200, s: 1, v: 1})
  def Lissajous(a: 3, b: 2, delta: 0, rx: 5, ry: 5, steps: 128, bold: 0, color:, z: 0)
    points = (steps + 1).times.map do |i|
      t = i * Math::PI * 2 / steps
      [Math.sin(a * t + delta) * rx, Math.sin(b * t) * ry]
    end
    points.each_cons(2) do |(x1, y1), (x2, y2)|
      Line(x1: x1, y1: y1, x2: x2, y2: y2, color: color, z: z, bold: bold)
    end
  end

  def Text(str, x: 0, y: 0, size: 1, color:, align_x: :left, align_y: :middle, z: 0)
    px, py = vj_px(x, y)
    height = size * UNIT
    c = hsv_to_color(color)
    lines = str.empty? ? [''] : str.split("\n", -1)
    total = lines.size * height
    block_top = case align_y
                when :top    then py
                when :bottom then py - total
                else              py - total / 2.0
                end
    lines.each_with_index do |line, i|
      VjRenderer.current.draw_text(line, px, block_top + i * height, height, c, align_x, :top, z)
    end
  end

  def polar(r, theta)
    { x: r * Math.cos(theta), y: r * Math.sin(theta) }
  end

  # color は {h:, s:, v:} または {h:, s:, v:, a:} のハッシュで渡す。
  # 各キーが欠落した場合は h=0, s=1, v=1, a=255 で補完する（純粋な赤になる）。
  def hsv_to_color(hsv)
    h = (hsv[:h] || 0) % 360
    s = hsv[:s] || 1
    v = hsv[:v] || 1
    a = hsv[:a] || 255
    hi = (h / 60).to_i
    f  = h / 60.0 - hi
    p  = v * (1 - s)
    q  = v * (1 - f * s)
    t  = v * (1 - (1 - f) * s)
    r, g, b = [[v,t,p],[q,v,p],[p,v,t],[p,q,v],[t,p,v],[v,p,q]][hi]
    [(r * 255).to_i, (g * 255).to_i, (b * 255).to_i, a.to_i]
  end
end

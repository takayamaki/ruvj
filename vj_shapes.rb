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
    steps.times do |i|
      a1 = i     * Math::PI * 2 / steps
      a2 = (i+1) * Math::PI * 2 / steps
      c  = hsv_to_gosu(color)
      Gosu.draw_triangle(
        cx,                    cy,                    c,
        cx + Math.cos(a1) * pr, cy - Math.sin(a1) * pr, c,
        cx + Math.cos(a2) * pr, cy - Math.sin(a2) * pr, c,
        z
      )
    end
  end

  def Rect(x: 0, y: 0, w: 1, h: 1, color:, z: 0)
    px, py = vj_px(x, y)
    pw, ph = w * UNIT, h * UNIT
    Gosu.draw_rect(px - pw / 2, py - ph / 2, pw, ph, hsv_to_gosu(color), z)
  end

  def Triangle(x: 0, y: 0, size: 1, angle: 0, color:, z: 0)
    cx, cy = vj_px(x, y)
    r = size * UNIT
    c = hsv_to_gosu(color)
    3.times do |i|
      a1 = i       * Math::PI * 2 / 3 + angle
      a2 = (i + 1) * Math::PI * 2 / 3 + angle
      Gosu.draw_triangle(
        cx,                    cy,                    c,
        cx + Math.cos(a1) * r, cy - Math.sin(a1) * r, c,
        cx + Math.cos(a2) * r, cy - Math.sin(a2) * r, c,
        z
      )
    end
  end

  def Line(x1: 0, y1: 0, x2: 1, y2: 0, color:, z: 0)
    px1, py1 = vj_px(x1, y1)
    px2, py2 = vj_px(x2, y2)
    c = hsv_to_gosu(color)
    Gosu.draw_line(px1, py1, c, px2, py2, c, z)
  end

  def Bg(color:)
    Gosu.draw_rect(0, 0, W, H, hsv_to_gosu(color), 0)
  end

  def hsv_to_gosu(hsv)
    h, s, v, a = hsv[0], hsv[1], hsv[2], (hsv[3] || 255)
    h = h % 360
    hi = (h / 60).to_i
    f  = h / 60.0 - hi
    p  = v * (1 - s)
    q  = v * (1 - f * s)
    t  = v * (1 - (1 - f) * s)
    r, g, b = [[v,t,p],[q,v,p],[p,v,t],[p,q,v],[t,p,v],[v,p,q]][hi]
    Gosu::Color.new(a.to_i, (r * 255).to_i, (g * 255).to_i, (b * 255).to_i)
  end
end

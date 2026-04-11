module VjShapes
  W    = 1280
  H    = 720
  UNIT = 40.0

  def vj_px(x, y)
    [W / 2.0 + x * UNIT, H / 2.0 - y * UNIT]
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

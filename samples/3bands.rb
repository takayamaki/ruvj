class RuVJ
  def draw_scene
    Bg(color: {h: 0, s: 0, v: 0.02})
    Circle(x: -10, y: 0, r: 1 + @vj.low * 4, color: {h:   0, s: 1, v: 1})
    Circle(x:   0, y: 0, r: 1 + @vj.mid * 4, color: {h: 120, s: 1, v: 1})
    Circle(x:  10, y: 0, r: 1 + @vj.hi  * 4, color: {h: 240, s: 1, v: 1})
  end
end

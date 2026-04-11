class RuVJ
  def draw_scene
    Bg(color: [0, 0, 0.05])
    Circle(x:10, r: @vj.hi*5, color: [180, 1, 1])
    Triangle(size: @vj.mid*5, angle: @vj.mid*5, color: [90, 1, 1])
    Rect(x: -10, h: @vj.low*5, w: @vj.low*5, color: [0, 1, 1])
    Bg(color: [0, 0, 1, (@vj.beat * 30).to_i]) 
  end
end

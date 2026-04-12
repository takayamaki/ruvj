class RuVJ
  def draw_scene
    Bg(color: [0, 0, 0.05])
    (-8..8).step(3).each do |j|
      (-15..15).step(3).each do |i|
        Circle(y: j,x: i, r: @vj.hi*1.5, color: [0, 1, 1]) if i.odd?
        Triangle(y: 0, x: i, size: @vj.mid*3, angle: @vj.mid*5*i, color: [90, 1, 1])
        Rect(y: -j, x: -i, h: @vj.low*3, w: @vj.low*3, color: [180, 1, 1]) if i.even?
      end
    end
    Bg(color: [0, 0, 1, (@vj.beat * 150)]) 
  end
end

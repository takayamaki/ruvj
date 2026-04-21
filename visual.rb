class RuVJ
  def draw_scene
    Bg(color: {h: 0, s: 0, v: 0.05})
    (-8..8).step(3).each do |j|
      (-15..15).step(3).each do |i|
        Circle(y: j,x: i, r: @vj.hi*1.5, color: {h: 0, s: 1, v: 1}) if i.odd?
        Triangle(y: 0, x: i, size: @vj.mid*3, angle: @vj.mid*5*i, color: {h: 90, s: 1, v: 1})
        Rect(y: -j, x: -i, h: @vj.low*3, w: @vj.low*3, color: {h: 180, s: 1, v: 1}) if i.even?
      end
    end
    Bg(color: {h: 0, s: 0, v: 1, a: (@vj.beat * 150)})
  end
end

class RuVJ
  def draw
    Bg(color: [0, 0, 0.05])
    Circle(r: 1 + @vj.phase * 3, color: [@vj.phase * 360, 1, 1])
    Bg(color: [0, 0, 1, 60]) if @vj.beat?
  end
end

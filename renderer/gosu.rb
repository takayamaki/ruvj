require_relative 'base'

class GosuRenderer
  def draw_triangle(x1, y1, c1, x2, y2, c2, x3, y3, c3, z = 0)
    Gosu.draw_triangle(
      x1, y1, gosu_color(c1),
      x2, y2, gosu_color(c2),
      x3, y3, gosu_color(c3),
      z
    )
  end

  def draw_rect(x, y, w, h, color, z = 0)
    Gosu.draw_rect(x, y, w, h, gosu_color(color), z)
  end

  def draw_line(x1, y1, c1, x2, y2, c2, z = 0)
    Gosu.draw_line(x1, y1, gosu_color(c1), x2, y2, gosu_color(c2), z)
  end

  def translate(x, y, &block) = Gosu.translate(x, y, &block)
  def scale(s, &block)        = Gosu.scale(s, s, &block)

  private

  def gosu_color(c)
    r, g, b, a = c
    Gosu::Color.new(a || 255, r, g, b)
  end
end

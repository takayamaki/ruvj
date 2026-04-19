require_relative '../../lib/renderer/base'

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

  def draw_text(text, x, y, height, color, align_x, align_y, z)
    font = (@fonts ||= {})[height] ||= Gosu::Font.new(height)
    w = font.text_width(text)
    ox = case align_x
         when :center then -w / 2.0
         when :right  then -w.to_f
         else              0.0
         end
    oy = case align_y
         when :top    then 0.0
         when :bottom then -height.to_f
         else              -height / 2.0
         end
    font.draw_text(text, x + ox, y + oy, z, 1, 1, gosu_color(color))
  end

  def translate(x, y, &block)              = Gosu.translate(x, y, &block)
  def scale(s, &block)                     = Gosu.scale(s, s, &block)
  def rotate(angle, cx = 640.0, cy = 360.0, &block) = Gosu.rotate(angle, cx, cy, &block)

  private

  def gosu_color(c)
    r, g, b, a = c
    Gosu::Color.new(a || 255, r, g, b)
  end
end

require 'gosu'

class TestWindow < Gosu::Window
  def initialize
    super(1280, 720)
    self.caption = 'RuVJ'
    @font = Gosu::Font.new(48)
  end

  def draw
    # 背景に矩形
    Gosu.draw_rect(540, 260, 200, 200, Gosu::Color::CYAN)
    # テキスト
    @font.draw_text('RuVJ', 560, 330, 1, 1, 1, Gosu::Color::BLACK)
  end

  def button_down(id)
    close if id == Gosu::KB_ESCAPE
  end
end

TestWindow.new.show

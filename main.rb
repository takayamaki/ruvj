require 'gosu'
require_relative 'beat'
require_relative 'vj_context'
require_relative 'vj_shapes'

class RuVJ < Gosu::Window
  include VjShapes

  def initialize
    super(W, H, fullscreen: false)
    self.caption = 'RuVJ'

    @beat = Beat.new
    @vj   = VJContext.new(beat: @beat)

    @visual_path  = File.expand_path('visual.rb', __dir__)
    @last_loaded  = Time.at(0)
    reload_visual
  end

  def update
    @beat.update
    @vj.update
    reload_visual if File.mtime(@visual_path) > @last_loaded
  end

  def draw
    # visual.rb が RuVJ#draw を上書きする
    # ロード前のフォールバック
    Bg(color: [0, 0, 0])
  end

  def button_down(id)
    case id
    when Gosu::KB_ESCAPE then close
    when Gosu::KB_SPACE  then @beat.tap!
    when Gosu::KB_R      then @last_loaded = Time.at(0)
    when Gosu::KB_UP     then @beat.bpm += 1
    when Gosu::KB_DOWN   then @beat.bpm -= 1
    end
  end

  private

  def reload_visual
    load @visual_path
    @last_loaded = Time.now
  rescue => e
    $stderr.puts "reload error: #{e.message}"
  end
end

RuVJ.new.show

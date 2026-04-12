require 'gosu'
require_relative 'beat'
require_relative 'audio'
require_relative 'vj_context'
require_relative 'vj_shapes'

class RuVJ < Gosu::Window
  include VjShapes

  def initialize
    super(W, H, resizable: true)
    self.caption = 'RuVJ'

    @beat  = Beat.new
    @audio = Audio.new(beat_fallback: @beat)
    @vj    = VJContext.new(beat: @beat, audio: @audio)

    @visual_path  = File.expand_path('visual.rb', __dir__)
    @last_loaded  = Time.at(0)
    reload_visual
  end

  def update
    @beat.update
    @audio.update
    @vj.update
    reload_visual if File.mtime(@visual_path) > @last_loaded
  end

  def draw
    s  = [width.to_f / W, height.to_f / H].max
    ox = (width  - W * s) / 2.0
    oy = (height - H * s) / 2.0
    Gosu.translate(ox, oy) { Gosu.scale(s, s) { draw_scene } }
  rescue Exception => e
    $stderr.puts "draw error: #{e.message}"
  end

  def draw_scene
    Bg(color: [0, 0, 0])
  end

  def button_down(id)
    case id
    when Gosu::KB_ESCAPE then close
    when Gosu::KB_F11    then self.fullscreen = !fullscreen?
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
    $stderr.puts "reloading visual.rb..."
  rescue Exception => e
    $stderr.puts "reload error: #{e.message}"
  end
end

RuVJ.new.show

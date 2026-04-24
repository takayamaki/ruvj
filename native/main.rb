GC.auto_compact = false  # Gosu 1.4.6 が Ruby 4.0 コンパクション未対応のため無効化

require 'gosu'
require_relative 'beat'
require_relative 'audio'
require_relative 'osc_receiver'
require_relative '../lib/vj_context'
require_relative '../lib/vj_shapes'
require_relative '../lib/vj_effects/spectrum'
require_relative '../lib/vj_effects/particles'
require_relative '../lib/vj_effects/warp'
require_relative '../lib/vj_effects/recording_renderer'
require_relative '../lib/vj_effects/trail'
require_relative '../lib/vj_effects/ripple'
require_relative 'renderer/gosu'

class RuVJ < Gosu::Window
  include VjShapes
  include VjEffects
  include VjEffects::Spectrum

  def initialize
    super(W, H, resizable: true)
    self.caption = 'RuVJ'

    @renderer = GosuRenderer.new
    VjRenderer.use(@renderer)

    @beat  = Beat.new
    # RUVJ_NO_CALIB=1 で起動時フロアノイズ学習をスキップ（既に音が鳴ってる状態で起動するとき用）
    @audio = Audio.new(beat_fallback: @beat, calibrate: ENV['RUVJ_NO_CALIB'].to_s.empty?)
    @osc   = OscReceiver.new
    @vj    = VJContext.new(beat: @beat, audio: @audio, osc: @osc)

    @visual_path  = ARGV[0] ? File.expand_path(ARGV[0]) : File.expand_path('../visual.rb', __dir__)
    @last_loaded  = Time.at(0)
    reload_visual
  end

  def update
    @beat.update
    @audio.update
    @vj.update
    reload_visual if File.mtime(@visual_path) > @last_loaded
    self.caption = "RuVJ  #{Gosu.fps} fps"
  end

  def draw
    s  = [width.to_f / W, height.to_f / H].max
    ox = (width  - W * s) / 2.0
    oy = (height - H * s) / 2.0
    @renderer.translate(ox, oy) { @renderer.scale(s) { draw_scene } }
  rescue Exception => e
    $stderr.puts "draw error: #{e.message}"
  end

  def draw_scene
    Bg(color: {h: 0, s: 0, v: 0})
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

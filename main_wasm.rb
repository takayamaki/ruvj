require 'js'
JS.eval("console.log('[RuVJ] script start')")

begin; require_relative 'vj_context';            JS.eval("console.log('[RuVJ] vj_context loaded')")
rescue => e; JS.eval("console.error('[RuVJ] FAILED vj_context: #{e.message}')"); end

begin; require_relative 'vj_shapes';             JS.eval("console.log('[RuVJ] vj_shapes loaded')")
rescue => e; JS.eval("console.error('[RuVJ] FAILED vj_shapes: #{e.message}')"); end

begin; require_relative 'renderer/webgl';        JS.eval("console.log('[RuVJ] renderer/webgl loaded')")
rescue => e; JS.eval("console.error('[RuVJ] FAILED renderer/webgl: #{e.message}')"); end

begin; require_relative 'audio_source/web_audio'; JS.eval("console.log('[RuVJ] audio_source/web_audio loaded')")
rescue => e; JS.eval("console.error('[RuVJ] FAILED audio_source/web_audio: #{e.message}')"); end

JS.eval("console.log('[RuVJ] all requires done')")

class RuVJWasm
  include VjShapes

  def initialize
    JS.eval("console.log('[RuVJ] RuVJWasm.new')")
    @renderer = WebGLRenderer.new(canvas_id: 'canvas')
    VjRenderer.use(@renderer)
    @audio = WebAudioSource.new
    @vj    = VJContext.new(audio: @audio)
    @last_src   = nil
    @tick_count = 0
    JS.eval("console.log('[RuVJ] RuVJWasm ready')")
  end

  def tick
    @audio.update
    @vj.update
    check_hot_reload

    @renderer.begin_frame
    draw_scene
    @renderer.flush!

    @tick_count += 1
    if @tick_count % 120 == 0
      JS.global[:console].call(:log, "[RuVJ] tick=#{@tick_count} amp=#{@vj.amp.round(3)}")
    end
  rescue => e
    JS.global[:console].call(:error, "[RuVJ] tick error: #{e.message} @ #{e.backtrace&.first}")
  end

  def draw_scene
    Bg(color: [0, 0, 0])
  end

  private

  def check_hot_reload
    el = JS.global[:document].call(:getElementById, 'visual-src')
    return unless el && el != JS.eval("null")
    src = el[:value].to_s
    return if src == @last_src
    instance_eval(src)
    @last_src = src
    JS.eval("console.log('[RuVJ] visual reloaded')")
  rescue => e
    JS.global[:console].call(:warn, "[RuVJ] reload error: #{e.message}")
  end
end

# JS 側から $ruvj_app.tick を呼ぶ。rAF ループは index.html の JS が担当
JS.eval("console.log('[RuVJ] registering __ruVjStart')")
JS.global[:__ruVjStart] = -> {
  JS.eval("console.log('[RuVJ] __ruVjStart called')")
  $ruvj_app = RuVJWasm.new
  JS.eval("window.__ruVjReady = true")
}

if JS.global[:__ruVjPendingStart].to_s == 'true'
  JS.eval("console.log('[RuVJ] PendingStart path')")
  $ruvj_app = RuVJWasm.new
  JS.eval("window.__ruVjReady = true")
end

JS.eval("console.log('[RuVJ] script end')")

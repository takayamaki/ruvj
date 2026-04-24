require_relative 'recording_renderer'

module VjEffects
  # ブロック内の描画を毎フレーム記録して直近 len フレーム分を alpha fade しながら
  # 再生する。Gosu は毎フレーム画面を clear するので半透明 Bg 方式は使えず、
  # 履歴を自前で保持する必要がある。
  #
  # visual.rb 使用例:
  #   @@trail ||= Trail.new(len: 60)
  #   def draw_scene
  #     Bg(color: {h: 0, s: 0, v: 0})
  #     @@trail.update do
  #       Circle(x: Math.sin(@vj.t*2)*10, y: 0, r: 0.5, color: {h: 180, s: 1, v: 1})
  #     end
  #   end
  class Trail
    def initialize(len: 60)
      @len    = len
      @frames = []
    end

    def update(&block)
      rec = RecordingRenderer.new
      VjRenderer.use(rec) { block.call }
      @frames << rec.commands
      @frames.shift while @frames.size > @len

      target = VjRenderer.current
      @frames.each_with_index do |cmds, i|
        fade = (i + 1.0) / @frames.size
        replay_commands(cmds, target, fade)
      end
    end

    private

    def replay_commands(cmds, target, alpha_mul)
      replayer = RecordingRenderer.new
      cmds.each { |c| replayer.commands << c }
      replayer.replay(target, alpha_mul: alpha_mul)
    end
  end
end

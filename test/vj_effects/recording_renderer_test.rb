require 'minitest/autorun'

module Gosu
  class Color
    attr_reader :alpha, :red, :green, :blue
    def initialize(a, r, g, b)
      @alpha, @red, @green, @blue = a, r, g, b
    end
  end

  DrawCall = Struct.new(:method, :args) unless defined?(DrawCall)
  DRAW_LOG = [] unless defined?(DRAW_LOG)
end

require_relative '../../lib/renderer/base'
require_relative '../../lib/vj_effects/recording_renderer'

class RecordingRendererTest < Minitest::Test
  RR = VjEffects::RecordingRenderer

  # --- 記録: 典型的な draw_* 呼び出し ---
  def test_draw_triangle_is_recorded_as_command
    skip
  end

  def test_draw_rect_is_recorded_as_command
    skip
  end

  def test_draw_line_is_recorded_as_command
    skip
  end

  def test_draw_text_is_recorded_as_command
    skip
  end

  # --- transform は素通し ---
  def test_translate_yields_block_without_recording
    skip
  end

  def test_scale_yields_block_without_recording
    skip
  end

  def test_rotate_yields_block_without_recording
    skip
  end

  # --- replay: alpha 乗算つき再生 ---
  def test_replay_forwards_triangle_with_alpha_multiplied
    skip
  end

  def test_replay_forwards_rect_with_alpha_multiplied
    skip
  end

  def test_replay_clamps_alpha_to_0_255
    skip
  end

  def test_replay_preserves_rgb_components
    skip
  end
end

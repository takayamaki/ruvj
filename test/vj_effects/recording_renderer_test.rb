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

  class MockTarget
    attr_reader :calls
    def initialize; @calls = []; end
    def draw_triangle(*a) = @calls << [:triangle, a]
    def draw_rect(*a)     = @calls << [:rect, a]
    def draw_line(*a)     = @calls << [:line, a]
    def draw_text(*a)     = @calls << [:text, a]
  end

  # --- 記録: 典型的な draw_* 呼び出し ---
  def test_draw_triangle_is_recorded_as_command
    rr = RR.new
    rr.draw_triangle(1, 2, [10, 20, 30, 255], 3, 4, [40, 50, 60, 255], 5, 6, [70, 80, 90, 255], 7)
    assert_equal 1, rr.commands.size
    assert_equal :triangle, rr.commands[0].kind
    assert_equal [1, 2, [10, 20, 30, 255], 3, 4, [40, 50, 60, 255], 5, 6, [70, 80, 90, 255], 7], rr.commands[0].args
  end

  def test_draw_rect_is_recorded_as_command
    rr = RR.new
    rr.draw_rect(0, 0, 100, 200, [255, 0, 0, 255], 0)
    assert_equal :rect, rr.commands[0].kind
    assert_equal [0, 0, 100, 200, [255, 0, 0, 255], 0], rr.commands[0].args
  end

  def test_draw_line_is_recorded_as_command
    rr = RR.new
    rr.draw_line(0, 0, [1, 2, 3, 255], 10, 10, [4, 5, 6, 255], 1)
    assert_equal :line, rr.commands[0].kind
  end

  def test_draw_text_is_recorded_as_command
    rr = RR.new
    rr.draw_text('hi', 0, 0, 40, [0, 0, 0, 255], :left, :top, 0)
    assert_equal :text, rr.commands[0].kind
  end

  # --- transform は素通し ---
  def test_translate_yields_block_without_recording
    rr = RR.new
    called = false
    rr.translate(10, 20) { called = true }
    assert called
    assert_empty rr.commands
  end

  def test_scale_yields_block_without_recording
    rr = RR.new
    called = false
    rr.scale(2.0) { called = true }
    assert called
    assert_empty rr.commands
  end

  def test_rotate_yields_block_without_recording
    rr = RR.new
    called = false
    rr.rotate(45) { called = true }
    assert called
    assert_empty rr.commands
  end

  # --- replay: alpha 乗算つき再生 ---
  def test_replay_forwards_triangle_with_alpha_multiplied
    rr = RR.new
    rr.draw_triangle(0, 0, [10, 20, 30, 200], 1, 1, [10, 20, 30, 200], 2, 2, [10, 20, 30, 200], 0)
    target = MockTarget.new
    rr.replay(target, alpha_mul: 0.5)
    kind, args = target.calls[0]
    assert_equal :triangle, kind
    assert_equal [10, 20, 30, 100], args[2]
    assert_equal [10, 20, 30, 100], args[5]
    assert_equal [10, 20, 30, 100], args[8]
  end

  def test_replay_forwards_rect_with_alpha_multiplied
    rr = RR.new
    rr.draw_rect(0, 0, 10, 10, [1, 2, 3, 100], 0)
    target = MockTarget.new
    rr.replay(target, alpha_mul: 0.3)
    kind, args = target.calls[0]
    assert_equal :rect, kind
    assert_equal [1, 2, 3, 30], args[4]
  end

  def test_replay_clamps_alpha_to_0_255
    rr = RR.new
    rr.draw_rect(0, 0, 10, 10, [0, 0, 0, 255], 0)
    target = MockTarget.new
    rr.replay(target, alpha_mul: 2.0)
    assert_equal 255, target.calls[0][1][4][3]
  end

  def test_replay_preserves_rgb_components
    rr = RR.new
    rr.draw_rect(0, 0, 10, 10, [11, 22, 33, 100], 0)
    target = MockTarget.new
    rr.replay(target, alpha_mul: 0.5)
    rgb = target.calls[0][1][4][0..2]
    assert_equal [11, 22, 33], rgb
  end
end

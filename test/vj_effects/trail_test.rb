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
require_relative '../../lib/vj_effects/trail'

class TrailTest < Minitest::Test
  T = VjEffects::Trail

  class MockTarget
    attr_reader :calls
    def initialize; @calls = []; end
    def draw_triangle(*a) = @calls << [:triangle, a]
    def draw_rect(*a)     = @calls << [:rect, a]
    def draw_line(*a)     = @calls << [:line, a]
    def draw_text(*a)     = @calls << [:text, a]
  end

  def draw_one_triangle
    VjRenderer.current.draw_triangle(
      0, 0, [100, 100, 100, 255],
      1, 1, [100, 100, 100, 255],
      2, 2, [100, 100, 100, 255],
      0
    )
  end

  # --- 典型: ブロック内の描画が記録され、replay される ---
  def test_update_records_block_draw_commands_and_replays_once_on_first_frame
    trail = T.new(len: 5)
    target = MockTarget.new
    VjRenderer.use(target) do
      trail.update { draw_one_triangle }
    end
    assert_equal 1, target.calls.count { |c| c[0] == :triangle }
  end

  def test_update_replays_all_stored_frames_on_each_call
    trail = T.new(len: 5)
    target = MockTarget.new
    VjRenderer.use(target) do
      3.times { trail.update { draw_one_triangle } }
    end
    # 1 + 2 + 3 = 6
    assert_equal 6, target.calls.count { |c| c[0] == :triangle }
  end

  # --- 履歴長 ---
  def test_frames_are_capped_at_len_and_oldest_are_shifted_out
    trail = T.new(len: 2)
    target = MockTarget.new
    VjRenderer.use(target) do
      4.times { trail.update { draw_one_triangle } }
    end
    # len=2 で cap されると 1+2+2+2 = 7 (無制限なら 1+2+3+4=10)
    assert_equal 7, target.calls.count { |c| c[0] == :triangle }
  end

  # --- fade ---
  def test_oldest_frame_has_smallest_alpha_newest_has_full_alpha
    trail = T.new(len: 3)
    target = MockTarget.new
    VjRenderer.use(target) do
      3.times { trail.update { draw_one_triangle } }
    end
    alphas_last3 = target.calls.last(3).map { |c| c[1][2][3] }
    assert alphas_last3[0] < alphas_last3[1]
    assert alphas_last3[1] < alphas_last3[2]
    assert_equal 255, alphas_last3[2]
  end

  # --- self 保持 ---
  def test_block_is_called_with_caller_self_preserved
    trail = T.new(len: 2)
    target = MockTarget.new
    caller_self = self
    captured = nil
    VjRenderer.use(target) do
      trail.update { captured = self }
    end
    assert_same caller_self, captured
  end
end

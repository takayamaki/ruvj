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
  # --- 典型: ブロック内の描画が記録され、過去フレームも replay される ---
  def test_update_records_block_draw_commands_and_replays_once_on_first_frame
    skip
  end

  def test_update_replays_all_stored_frames_on_each_call
    skip
  end

  # --- 履歴長 ---
  def test_frames_are_capped_at_len_and_oldest_are_shifted_out
    skip
  end

  # --- fade ---
  def test_oldest_frame_has_smallest_alpha_newest_has_full_alpha
    skip
  end

  # --- self 保持 ---
  def test_block_is_called_with_caller_self_preserved
    skip
  end
end

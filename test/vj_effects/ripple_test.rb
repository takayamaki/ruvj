require 'minitest/autorun'
require_relative '../../lib/vj_effects/ripple'

class RippleTest < Minitest::Test
  # --- 典型: emit で 1 drop 発生、r/alpha がブロックに渡る ---
  def test_update_with_emit_true_adds_one_drop_and_calls_block_once
    skip
  end

  def test_block_receives_r_and_alpha_keyword_args
    skip
  end

  def test_r_increases_by_speed_per_frame
    skip
  end

  def test_alpha_decreases_as_life_decreases
    skip
  end

  # --- emit 条件 ---
  def test_update_with_emit_false_does_not_add_drop
    skip
  end

  def test_multiple_drops_emit_independently_over_frames
    skip
  end

  # --- life 満了 ---
  def test_drop_is_removed_when_life_reaches_zero
    skip
  end

  # --- max 制限 ---
  def test_emit_is_suppressed_when_drops_reach_max
    skip
  end
end

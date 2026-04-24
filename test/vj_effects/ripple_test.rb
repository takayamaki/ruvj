require 'minitest/autorun'
require_relative '../../lib/vj_effects/ripple'

class RippleTest < Minitest::Test
  R = VjEffects::Ripple

  # --- 典型: emit で 1 drop 発生、r/alpha がブロックに渡る ---
  def test_update_with_emit_true_adds_one_drop_and_calls_block_once
    rip = R.new(max: 10, speed: 0.2, life: 60, r_start: 0.5)
    calls = 0
    rip.update(emit: true) { |r:, alpha:| calls += 1 }
    assert_equal 1, calls
  end

  def test_block_receives_r_and_alpha_keyword_args
    rip = R.new(max: 10, speed: 0.2, life: 60, r_start: 0.5)
    result = nil
    rip.update(emit: true) { |r:, alpha:| result = { r: r, alpha: alpha } }
    refute_nil result
    assert_kind_of Numeric, result[:r]
    assert_kind_of Integer, result[:alpha]
  end

  def test_r_increases_by_speed_per_frame
    rip = R.new(max: 10, speed: 0.5, life: 60, r_start: 0.0)
    rs = []
    rip.update(emit: true)  { |r:, alpha:| rs << r }
    rip.update(emit: false) { |r:, alpha:| rs << r }
    assert_in_delta 0.5, rs[0], 0.01
    assert_in_delta 1.0, rs[1], 0.01
  end

  def test_alpha_decreases_as_life_decreases
    rip = R.new(max: 10, speed: 0.1, life: 60)
    alphas = []
    3.times { |i| rip.update(emit: i.zero?) { |r:, alpha:| alphas << alpha } }
    assert alphas[0] > alphas[1]
    assert alphas[1] > alphas[2]
  end

  # --- emit 条件 ---
  def test_update_with_emit_false_does_not_add_drop
    rip = R.new(max: 10, speed: 0.1, life: 60)
    calls = 0
    rip.update(emit: false) { |r:, alpha:| calls += 1 }
    assert_equal 0, calls
  end

  def test_multiple_drops_emit_independently_over_frames
    rip = R.new(max: 10, speed: 0.1, life: 60)
    rip.update(emit: true) { |r:, alpha:| }
    rip.update(emit: true) { |r:, alpha:| }
    count = 0
    rip.update(emit: false) { |r:, alpha:| count += 1 }
    assert_equal 2, count
  end

  # --- life 満了 ---
  def test_drop_is_removed_when_life_reaches_zero
    rip = R.new(max: 10, speed: 0.1, life: 3)
    3.times { |i| rip.update(emit: i.zero?) { |r:, alpha:| } }
    count = 0
    rip.update(emit: false) { |r:, alpha:| count += 1 }
    assert_equal 0, count
  end

  # --- max 制限 ---
  def test_emit_is_suppressed_when_drops_reach_max
    rip = R.new(max: 2, speed: 0.1, life: 60)
    rip.update(emit: true) { |r:, alpha:| }
    rip.update(emit: true) { |r:, alpha:| }
    count = 0
    rip.update(emit: true) { |r:, alpha:| count += 1 }
    assert_equal 2, count
  end
end

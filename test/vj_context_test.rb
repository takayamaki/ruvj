require 'minitest/autorun'
require_relative '../beat'

# Audio スタブ（Ractor なし、テスト用）
module AudioStub
  SAMPLE_RATE = 48000
  CHUNK_SIZE  = 1024

  class Flat
    attr_reader :amp, :low, :mid, :hi

    def initialize(spectrum: nil, amp: 0.0, low: 0.0, mid: 0.0, hi: 0.0)
      @spectrum = spectrum || Array.new(CHUNK_SIZE / 2, 0.0)
      @amp = amp; @low = low; @mid = mid; @hi = hi
    end

    def beat? = false
    def spectrum = @spectrum
  end
end

# Audio 定数を解決するためのエイリアス
Audio = AudioStub unless defined?(Audio)

require_relative '../vj_context'

class VJContextSpectrumTest < Minitest::Test
  def setup
    @beat = Beat.new
  end

  # --- audio なし ---
  def test_spectrum_returns_all_zeros_when_audio_is_nil
    vj = VJContext.new(beat: @beat)
    assert_equal Array.new(32, 0.0), vj.spectrum
  end

  # --- デフォルト動作 ---
  def test_spectrum_returns_array_of_32_floats_by_default
    vj = VJContext.new(beat: @beat, audio: AudioStub::Flat.new)
    result = vj.spectrum
    assert_equal 32, result.size
    assert result.all? { _1.is_a?(Float) }
  end

  def test_all_values_are_between_0_and_1
    raw = Array.new(512) { rand }
    vj  = VJContext.new(beat: @beat, audio: AudioStub::Flat.new(spectrum: raw))
    vj.spectrum.each { |v| assert_operator v, :>=, 0.0; assert_operator v, :<=, 1.0 }
  end

  # --- n パラメータ ---
  def test_spectrum_n_controls_number_of_bins
    vj = VJContext.new(beat: @beat, audio: AudioStub::Flat.new)
    assert_equal 16, vj.spectrum(16).size
    assert_equal 64, vj.spectrum(64).size
  end

  # --- 値の正確さ ---
  def test_high_amplitude_spectrum_produces_nonzero_values
    raw = Array.new(512, 1.0)
    vj  = VJContext.new(beat: @beat, audio: AudioStub::Flat.new(spectrum: raw))
    assert vj.spectrum.any? { _1 > 0.0 }
  end

  def test_low_frequency_energy_appears_in_early_bins
    raw       = Array.new(512, 0.0)
    raw[1]    = 1.0   # 最低域ビン
    vj        = VJContext.new(beat: @beat, audio: AudioStub::Flat.new(spectrum: raw))
    result    = vj.spectrum(32)
    assert_operator result.first(4).max, :>, result.last(4).max
  end

  def test_high_frequency_energy_appears_in_late_bins
    raw       = Array.new(512, 0.0)
    raw[500]  = 1.0   # 最高域ビン
    vj        = VJContext.new(beat: @beat, audio: AudioStub::Flat.new(spectrum: raw))
    result    = vj.spectrum(32)
    assert_operator result.last(4).max, :>, result.first(4).max
  end

  # --- ピーク追従 ---
  def test_repeated_calls_keep_values_within_0_to_1
    raw = Array.new(512) { rand * 100 }
    vj  = VJContext.new(beat: @beat, audio: AudioStub::Flat.new(spectrum: raw))
    10.times { vj.spectrum.each { |v| assert_operator v, :<=, 1.0 } }
  end
end

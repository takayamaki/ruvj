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
  end

  # --- デフォルト動作 ---
  def test_spectrum_returns_array_of_32_floats_by_default
  end

  def test_all_values_are_between_0_and_1
  end

  # --- n パラメータ ---
  def test_spectrum_n_controls_number_of_bins
  end

  # --- 値の正確さ ---
  def test_high_amplitude_spectrum_produces_nonzero_values
  end

  def test_low_frequency_energy_appears_in_early_bins
  end

  def test_high_frequency_energy_appears_in_late_bins
  end

  # --- ピーク追従 ---
  def test_repeated_calls_keep_values_within_0_to_1
  end
end

# WebAudio backend for Ruby WASM
#
# AudioContext / AnalyserNode は JS 側（index.html の START ボタン押下後）で
# セットアップ済みのものを window.__ruVjAudioCtx / __ruVjAnalyser から受け取る。
# Ractor 不要: AnalyserNode が FFT をネイティブで処理する。
#
# Duck type (Audio クラスと同じインターフェース):
#   amp, low, mid, hi, spectrum, waveform, beat?, update, sample_rate, fft_size
class WebAudioSource
  # バンド定義 (Hz)
  BAND_LOW = [20,   300]
  BAND_MID = [300,  4000]
  BAND_HI  = [4000, 20000]

  BEAT_HISTORY  = 43    # エネルギー履歴フレーム数
  BEAT_RATIO    = 1.4   # 平均エネルギーの何倍でビート判定
  BEAT_MIN_AMP  = 0.05  # ビート判定の最低振幅

  attr_reader :amp, :low, :mid, :hi, :spectrum, :waveform

  def initialize
    @analyser = JS.global[:__ruVjAnalyser]
    @ctx      = JS.global[:__ruVjAudioCtx]

    @fft_size = @analyser[:fftSize].to_i
    @bins     = @analyser[:frequencyBinCount].to_i

    @freq_data = JS.global[:Float32Array].new(@bins)
    @time_data = JS.global[:Float32Array].new(@fft_size)

    @amp = @low = @mid = @hi = 0.0
    @spectrum = Array.new(@bins, 0.0)
    @waveform = Array.new(256, 0.0)
    @beat_detected = false
    @energy_history = Array.new(BEAT_HISTORY, 0.0)
  end

  def sample_rate = @ctx[:sampleRate].to_i
  def fft_size    = @bins

  def update
    @analyser.call(:getFloatFrequencyData, @freq_data)
    @analyser.call(:getFloatTimeDomainData, @time_data)

    bin_hz = sample_rate.to_f / @fft_size

    # dBFS → linear (0–1): WebAudio は -Infinity〜0 dBFS を返す
    raw = Array.new(@bins) { |k|
      db = @freq_data[k].to_f
      db <= -100.0 ? 0.0 : (10.0 ** ((db + 100.0) / 20.0) / 10.0).clamp(0.0, 1.0)
    }
    @spectrum = raw

    @low = band_rms(raw, bin_hz, *BAND_LOW)
    @mid = band_rms(raw, bin_hz, *BAND_MID)
    @hi  = band_rms(raw, bin_hz, *BAND_HI)
    @amp = Math.sqrt((@low**2 + @mid**2 + @hi**2) / 3.0).clamp(0.0, 1.0)

    # 波形（256サンプルに間引き）
    step = @fft_size / 256
    @waveform = Array.new(256) { |i| @time_data[i * step].to_f }

    # ビート検出（エネルギー履歴の移動平均と比較）
    @energy_history.shift
    @energy_history.push(@amp)
    avg = @energy_history.sum / BEAT_HISTORY
    @beat_detected = @amp > avg * BEAT_RATIO && @amp > BEAT_MIN_AMP
  end

  def beat?
    flag = @beat_detected
    @beat_detected = false
    flag
  end

  private

  def band_rms(raw, bin_hz, f_lo, f_hi)
    lo = (f_lo / bin_hz).floor.clamp(0, @bins - 1)
    hi = (f_hi / bin_hz).ceil.clamp(0, @bins - 1)
    slice = raw[lo..hi]
    return 0.0 if slice.empty?
    Math.sqrt(slice.sum { |v| v * v } / slice.size).clamp(0.0, 1.0)
  end
end

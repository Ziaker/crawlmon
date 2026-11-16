class_name NatureSlotSfx
extends RefCounted
## Synthesised sounds of the Nature slot machine (D-1215), a 1:1 port of the `Sfx`
## recipes in prototypes/nature_slot/nature_slot.html (WebAudio tone()/noise()):
## start, tick, stop ("ka-chunk + ding"), win ("ta ta na NAM"), pure, stamp.
## Everything is rendered once into AudioStreamWAV buffers and cached.

const RATE := 22050
const MASTER := 0.6
const BELLS: Array[float] = [659.25, 830.61, 987.77]

static var _cache: Dictionary = {}


static func stream(kind: String, reel_index: int = 0) -> AudioStreamWAV:
	var key := "%s_%d" % [kind, clampi(reel_index, 0, 2)]
	if _cache.has(key):
		return _cache[key] as AudioStreamWAV
	var buf := _render(kind, clampi(reel_index, 0, 2))
	var wav := _to_wav(buf)
	_cache[key] = wav
	return wav


static func _render(kind: String, idx: int) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	match kind:
		"start":
			buf.resize(int(RATE * 0.4))
			_tone(buf, "sawtooth", 120.0, 0.3, 0.09, 340.0, 0.0)
			_tone(buf, "square", 240.0, 0.16, 0.04, 480.0, 0.03)
			_noise(buf, 0.18, 0.035, 1500.0, 1.1, 0.0)
		"tick":
			buf.resize(int(RATE * 0.06))
			var freq := 1150.0 + float(idx) * 80.0
			_tone(buf, "square", freq, 0.018, 0.045, freq, 0.0)
		"stop":
			buf.resize(int(RATE * 1.3))
			var bell: float = BELLS[idx]
			_tone(buf, "sine", 170.0, 0.34, 0.5, 38.0, 0.0)
			_tone(buf, "square", 92.0, 0.09, 0.16, 46.0, 0.0)
			_noise(buf, 0.07, 0.34, 2400.0, 3.2, 0.0)
			_noise(buf, 0.16, 0.2, 620.0, 0.8, 0.012)
			_tone(buf, "sine", bell, 1.1, 0.26, bell, 0.03)
			_tone(buf, "sine", bell * 2.756, 0.5, 0.11, bell * 2.756, 0.03)
			_tone(buf, "sine", bell * 5.404, 0.22, 0.05, bell * 5.404, 0.03)
			_tone(buf, "triangle", bell * 1.003, 0.8, 0.08, bell * 1.003, 0.03)
		"win":
			buf.resize(int(RATE * 1.8))
			_fanfare(buf, [523.25, 523.25, 659.25, 1046.5], "square", 1.0)
			for c in 8:
				_noise(buf, 0.06, 0.05, 2500.0 + float(c) * 300.0, 2.6, 0.6 + float(c) * 0.05)
		"pure":
			buf.resize(int(RATE * 1.8))
			_fanfare(buf, [392.0, 392.0, 493.88, 783.99], "triangle", 0.8)
		"whoosh":
			buf.resize(int(RATE * 0.7))
			_tone(buf, "sawtooth", 90.0, 0.5, 0.07, 420.0, 0.0)
			_noise(buf, 0.35, 0.2, 700.0, 0.7, 0.0)
			_noise(buf, 0.3, 0.16, 2200.0, 0.8, 0.28)
			_tone(buf, "sine", 150.0, 0.25, 0.3, 45.0, 0.45)
		"stamp":
			buf.resize(int(RATE * 0.3))
			_tone(buf, "sine", 96.0, 0.2, 0.17, 48.0, 0.0)
			_noise(buf, 0.08, 0.07, 430.0, 0.7, 0.0)
	return buf


static func _fanfare(buf: PackedFloat32Array, notes: Array, wave: String, level: float) -> void:
	var at: Array[float] = [0.0, 0.14, 0.28, 0.46]
	for i in 3:
		var n: float = notes[i]
		_tone(buf, wave, n, 0.11, 0.2 * level, n, at[i])
		_tone(buf, "triangle", n * 2.0, 0.1, 0.09 * level, n * 2.0, at[i])
		_noise(buf, 0.03, 0.08 * level, 3000.0, 1.5, at[i])
	var top: float = notes[3]
	_tone(buf, wave, top, 1.1, 0.2 * level, top, at[3])
	_tone(buf, wave, top * 0.7492, 1.1, 0.13 * level, top * 0.7492, at[3])
	_tone(buf, wave, top * 0.63, 1.1, 0.11 * level, top * 0.63, at[3])
	_tone(buf, "triangle", top * 2.0, 0.9, 0.1 * level, top * 2.0, at[3])
	_tone(buf, "sine", top * 0.25, 0.7, 0.3 * level, top * 0.25, at[3])
	_noise(buf, 0.25, 0.14 * level, 5200.0, 0.9, at[3])


## WebAudio oscillator + gain: 8 ms exponential attack to `peak`, exponential
## decay to 0.0001 at `dur`, optional exponential pitch slide.
static func _tone(buf: PackedFloat32Array, wave: String, freq: float, dur: float, peak: float, slide_to: float, delay: float) -> void:
	var start := int(delay * RATE)
	var count := int((dur + 0.03) * RATE)
	var phase := 0.0
	var f0 := maxf(20.0, freq)
	var f1 := maxf(20.0, slide_to)
	var pk := maxf(0.0002, peak)
	var d := maxf(0.02, dur)
	for n in count:
		var i := start + n
		if i >= buf.size():
			break
		var t := float(n) / float(RATE)
		var env := 0.0
		if t < 0.008:
			env = 0.0001 * pow(pk / 0.0001, t / 0.008)
		elif t < d:
			env = pk * pow(0.0001 / pk, (t - 0.008) / maxf(0.001, d - 0.008))
		var f := f0 * pow(f1 / f0, minf(t / d, 1.0)) if f1 != f0 else f0
		phase += TAU * f / float(RATE)
		var p := fmod(phase, TAU) / TAU
		var s := 0.0
		match wave:
			"sine":
				s = sin(phase)
			"square":
				s = 1.0 if p < 0.5 else -1.0
			"sawtooth":
				s = 2.0 * p - 1.0
			_:
				s = 4.0 * absf(p - 0.5) - 1.0
		buf[i] += s * env * MASTER


## WebAudio white noise -> band-pass biquad -> exponential decay gain.
static func _noise(buf: PackedFloat32Array, dur: float, peak: float, freq: float, q: float, delay: float) -> void:
	var start := int(delay * RATE)
	var count := int((dur + 0.03) * RATE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1215 + int(freq)
	var w0 := TAU * freq / float(RATE)
	var alpha := sin(w0) / (2.0 * q)
	var a0 := 1.0 + alpha
	var b0 := alpha / a0
	var b2 := -alpha / a0
	var a1 := -2.0 * cos(w0) / a0
	var a2 := (1.0 - alpha) / a0
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	var d := maxf(0.02, dur)
	for n in count:
		var i := start + n
		if i >= buf.size():
			break
		var t := float(n) / float(RATE)
		var x := rng.randf() * 2.0 - 1.0
		var y := b0 * x + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		var env := peak * pow(0.0001 / peak, minf(t / d, 1.0)) if t < d else 0.0
		buf[i] += y * env * MASTER


static func _to_wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav

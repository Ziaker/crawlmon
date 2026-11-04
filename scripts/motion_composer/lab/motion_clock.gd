class_name MotionClock
extends RefCounted
## Relógio local do laboratório (§9.1). É o ÚNICO tempo do laboratório: nenhum comportamento lê relógio
## próprio. Pausa mantém o tempo; a velocidade só muda o ritmo em que `time` avança, nunca a definição
## espacial da animação. No combate futuro o tempo virá do motor (D-019).

const SPEEDS: Array[float] = [0.1, 0.25, 0.5, 1.0, 2.0]
const STEP_SECONDS: float = 1.0 / 60.0

var time: float = 0.0
## Duração do ciclo de prévia em segundos (proposta: 3 s).
var duration: float = 3.0
var playing: bool = false
var speed: float = 1.0
var loop: bool = true
## Trecho repetido [loop_start, loop_end]; loop_end < 0 = até o fim.
var loop_start: float = 0.0
var loop_end: float = -1.0


func window_end() -> float:
	return duration if loop_end < 0.0 else minf(loop_end, duration)


## Início da janela de histórico: ao repetir um trecho, a cauda não cruza o início dele (§19.4).
func history_start() -> float:
	return loop_start if loop else 0.0


func play() -> void:
	playing = true


func pause() -> void:
	playing = false


func toggle() -> void:
	playing = not playing


func restart() -> void:
	time = loop_start if loop else 0.0


func seek(t: float) -> void:
	time = clampf(t, 0.0, duration)


## Avança `frames` passos de 1/60 s (negativo = retrocede). Pausa o relógio.
func step(frames: int) -> void:
	playing = false
	seek(time + STEP_SECONDS * float(frames))


func set_speed(s: float) -> void:
	speed = clampf(s, 0.01, 8.0)


func set_loop_window(from_t: float, to_t: float) -> void:
	loop_start = clampf(from_t, 0.0, duration)
	loop_end = -1.0 if to_t < 0.0 else clampf(to_t, loop_start, duration)
	if time < loop_start:
		time = loop_start


## Chamado a cada quadro com o delta real em segundos.
func advance(delta: float) -> void:
	if not playing:
		return
	time += delta * speed
	var end := window_end()
	if time >= end:
		if loop and end > loop_start:
			time = loop_start + fposmod(time - loop_start, end - loop_start)
		else:
			time = end
			playing = false

extends Node
## Ciclo de dia e noite. Duração total e fração de dia são configuráveis.
## PENDENTE: significado dos valores de dificuldade noturna 10, 12, 15 e 20 (não aplicado).

@export var cycle_seconds: float = 600.0   # 10 minutos
@export var day_fraction: float = 0.6      # parte do ciclo que é dia (configurável)

var sun: DirectionalLight3D
var env: Environment
const DAY_SKY := Color(0.45, 0.7, 0.95)
const NIGHT_SKY := Color(0.02, 0.03, 0.08)

func is_night() -> bool:
	return GameState.time_of_day >= day_fraction

func _process(delta: float) -> void:
	GameState.time_of_day = fposmod(GameState.time_of_day + delta / cycle_seconds, 1.0)
	_apply()

func _phase() -> float:
	var t: float = GameState.time_of_day
	if t < day_fraction:
		return 0.5 * t / day_fraction
	return 0.5 + 0.5 * (t - day_fraction) / (1.0 - day_fraction)

func _apply() -> void:
	if sun == null or env == null:
		return
	var ph := _phase()
	var elev := sin(ph * TAU)
	sun.rotation = Vector3(-ph * TAU, 0.6, 0)
	sun.light_energy = clampf(elev * 1.3, 0.0, 1.2)
	sun.visible = elev > 0.02
	var k := clampf(elev * 3.0 + 0.15, 0.0, 1.0)
	var sky := NIGHT_SKY.lerp(DAY_SKY, k)
	env.background_color = sky
	env.ambient_light_color = NIGHT_SKY.lerp(Color(0.8, 0.85, 0.9), k)
	env.ambient_light_energy = lerpf(0.25, 0.7, k)

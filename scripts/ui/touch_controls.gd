extends Control
## Analógico virtual flutuante (metade esquerda) e câmera por arrasto (lado direito).

const JOY_RADIUS := 110.0
var enabled: bool = true
var move_vec: Vector2 = Vector2.ZERO
var look_delta: Vector2 = Vector2.ZERO
var buttons: Array = []
var _joy_idx: int = -1
var _cam_idx: int = -1
var _center: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func consume_look() -> Vector2:
	var l := look_delta
	look_delta = Vector2.ZERO
	return l

func _on_button(p: Vector2) -> bool:
	for b in buttons:
		if b.is_visible_in_tree() and b.get_global_rect().has_point(p):
			return true
	return false

func _input(e: InputEvent) -> void:
	if not enabled:
		if _joy_idx != -1 or _cam_idx != -1:
			_joy_idx = -1
			_cam_idx = -1
			move_vec = Vector2.ZERO
			queue_redraw()
		return
	if e is InputEventScreenTouch:
		if e.pressed:
			if _on_button(e.position):
				return
			if _joy_idx == -1 and e.position.x < size.x * 0.4:
				_joy_idx = e.index
				_center = e.position
				_update(e.position)
			elif _cam_idx == -1 and e.position.x >= size.x * 0.4:
				_cam_idx = e.index
		else:
			if e.index == _joy_idx:
				_joy_idx = -1
				move_vec = Vector2.ZERO
				queue_redraw()
			elif e.index == _cam_idx:
				_cam_idx = -1
	elif e is InputEventScreenDrag:
		if e.index == _joy_idx:
			_update(e.position)
		elif e.index == _cam_idx:
			look_delta += e.relative

func _update(p: Vector2) -> void:
	var d := p - _center
	if d.length() > JOY_RADIUS:
		d = d.normalized() * JOY_RADIUS
	_knob = _center + d
	move_vec = d / JOY_RADIUS
	queue_redraw()

func _draw() -> void:
	var c := _center if _joy_idx != -1 else Vector2(170, size.y - 170)
	var k := _knob if _joy_idx != -1 else c
	draw_circle(c, JOY_RADIUS, Color(1, 1, 1, 0.12))
	draw_arc(c, JOY_RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.4), 3.0)
	draw_circle(k, 40, Color(1, 1, 1, 0.35))

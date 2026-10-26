extends CharacterBody3D
## Jogador em terceira pessoa. Modelo = PLACEHOLDER articulado feito com primitivas (não é o modelo final).
## As animações são PROCEDURAIS (código) e servem só até o modelo 3D rigged chegar.

const MeshUtil = preload("res://scripts/core/mesh_util.gd")
const GRAVITY := 20.0
const JUMP_VELOCITY := 7.0
const DODGE_SPEED := 11.0
const DODGE_TIME := 0.3

@export var look_sensitivity: float = 0.005

var hp: float = 100.0
var max_hp: float = 100.0
var speed: float = 5.0
var yaw: float = 0.0
var pitch: float = -0.35
var facing: float = 0.0
var touch = null
var jump_request: bool = false
var attack_cd: float = 0.0
var dodge_cd: float = 0.0
var dodge_t: float = 0.0
var invuln: float = 0.0
var attacking: bool = false
var last_dir: Vector3 = Vector3.ZERO
var dodge_dir: Vector3 = Vector3.ZERO
var anim_t: float = 0.0
var spawn_pos: Vector3 = Vector3(0, 0.5, 8)

var pivot: Node3D
var arm: SpringArm3D
var body: Node3D
var torso: MeshInstance3D
var leg_l: Node3D
var leg_r: Node3D
var arm_l: Node3D
var arm_r: Node3D

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	col.shape = cap
	col.position.y = 0.85
	add_child(col)
	_build_visual()

	pivot = Node3D.new()
	pivot.top_level = true
	add_child(pivot)
	arm = SpringArm3D.new()
	arm.spring_length = 5.0
	arm.margin = 0.3
	arm.collision_mask = 1
	pivot.add_child(arm)
	var cam := Camera3D.new()
	arm.add_child(cam)
	cam.current = true
	apply_state()
	hp = max_hp

func _limb(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	MeshUtil.add(n, MeshUtil.box(size), color, Vector3(0, -size.y / 2.0, 0))
	return n

func _build_visual() -> void:
	body = Node3D.new()
	add_child(body)
	var dark := Color(0.12, 0.12, 0.15)
	var red := Color(0.75, 0.1, 0.12)
	torso = MeshUtil.add(body, MeshUtil.capsule(0.3, 1.0), dark, Vector3(0, 1.05, 0))
	MeshUtil.add(body, MeshUtil.sphere(0.22), Color(0.95, 0.8, 0.7), Vector3(0, 1.68, 0))
	MeshUtil.add(body, MeshUtil.sphere(0.24), Color(0.05, 0.05, 0.07), Vector3(0, 1.74, 0.03), Vector3(1, 0.8, 1))
	MeshUtil.add(body, MeshUtil.cyl(0.27, 0.27, 0.1), red, Vector3(0, 1.42, 0))
	leg_l = _limb(body, Vector3(-0.12, 0.7, 0), Vector3(0.18, 0.7, 0.2), dark)
	leg_r = _limb(body, Vector3(0.12, 0.7, 0), Vector3(0.18, 0.7, 0.2), dark)
	MeshUtil.add(leg_l, MeshUtil.box(Vector3(0.2, 0.14, 0.28)), Color(0.4, 0.08, 0.08), Vector3(0, -0.64, -0.03))
	MeshUtil.add(leg_r, MeshUtil.box(Vector3(0.2, 0.14, 0.28)), Color(0.4, 0.08, 0.08), Vector3(0, -0.64, -0.03))
	arm_l = _limb(body, Vector3(-0.38, 1.4, 0), Vector3(0.14, 0.6, 0.14), dark)
	arm_r = _limb(body, Vector3(0.38, 1.4, 0), Vector3(0.14, 0.6, 0.14), dark)
	MeshUtil.add(arm_r, MeshUtil.box(Vector3(0.06, 0.06, 0.95)), Color(0.75, 0.75, 0.8), Vector3(0, -0.6, -0.45))  # espada

func apply_state() -> void:
	max_hp = GameState.max_hp()
	speed = GameState.move_speed()
	hp = minf(hp, max_hp)

func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_F: attack()
			KEY_G: attack_heavy()
			KEY_Q: dodge()
			KEY_E: interact()
			KEY_SPACE: jump_request = true

func _physics_process(delta: float) -> void:
	attack_cd = maxf(0.0, attack_cd - delta)
	dodge_cd = maxf(0.0, dodge_cd - delta)
	invuln = maxf(0.0, invuln - delta)
	var inp := Vector2.ZERO
	var look := Vector2.ZERO
	if touch:
		inp = touch.move_vec
		look = touch.consume_look()
	# Teclado (apenas para testes no computador)
	inp.x += float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	inp.y += float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	look.x += (float(Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_LEFT))) * 6.0
	look.y += (float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP))) * 6.0
	inp = inp.limit_length(1.0)

	yaw -= look.x * look_sensitivity
	pitch = clampf(pitch - look.y * look_sensitivity, -1.2, -0.05)

	var dir := Vector3(inp.x, 0, inp.y).rotated(Vector3.UP, yaw)
	if dir.length() > 0.1:
		last_dir = dir.normalized()
	var move_scale: float = 0.35 if attacking else 1.0
	if dodge_t > 0.0:
		dodge_t -= delta
		velocity.x = dodge_dir.x * DODGE_SPEED
		velocity.z = dodge_dir.z * DODGE_SPEED
	else:
		velocity.x = dir.x * speed * move_scale
		velocity.z = dir.z * speed * move_scale
	if is_on_floor():
		velocity.y = JUMP_VELOCITY if (jump_request and dodge_t <= 0.0) else -0.1
	else:
		velocity.y -= GRAVITY * delta
	jump_request = false
	move_and_slide()

	if dodge_t > 0.0:
		facing = atan2(-dodge_dir.x, -dodge_dir.z)
		body.rotation.y = facing
	elif dir.length() > 0.1 and not attacking:
		facing = lerp_angle(facing, atan2(-dir.x, -dir.z), 12.0 * delta)
		body.rotation.y = facing

	_animate(delta, Vector2(velocity.x, velocity.z).length())
	pivot.global_position = global_position + Vector3(0, 1.5, 0)
	pivot.rotation = Vector3(pitch, yaw, 0)
	if global_position.y < -20.0:
		_respawn()

# ---------- Animação procedural (placeholder) ----------
func _animate(delta: float, hspeed: float) -> void:
	anim_t += delta
	var ratio: float = clampf(hspeed / maxf(speed, 0.1), 0.0, 1.0)
	var swing: float = sin(anim_t * (7.0 + 5.0 * ratio)) * 0.8 * ratio
	torso.scale.y = 1.0 + 0.02 * sin(anim_t * 2.0)  # respiração (idle)
	var tilt: float = -0.6 if dodge_t > 0.0 else 0.0
	body.rotation.x = lerp_angle(body.rotation.x, tilt, 15.0 * delta)
	if dodge_t > 0.0:
		leg_l.rotation.x = 0.8
		leg_r.rotation.x = -0.8
		arm_l.rotation.x = -1.2
		if not attacking:
			arm_r.rotation.x = -1.2
	elif not is_on_floor():
		leg_l.rotation.x = 0.5
		leg_r.rotation.x = -0.4
		arm_l.rotation.x = 0.2
		arm_l.rotation.z = -0.6
		if not attacking:
			arm_r.rotation.x = 0.2
			arm_r.rotation.z = 0.6
	else:
		leg_l.rotation.x = swing
		leg_r.rotation.x = -swing
		arm_l.rotation.x = -swing
		arm_l.rotation.z = 0.0
		if not attacking:
			arm_r.rotation.x = 0.25 + swing
			arm_r.rotation.z = 0.0

# ---------- Combate ----------
func attack() -> void:
	_do_attack(false)

func attack_heavy() -> void:
	_do_attack(true)

func _do_attack(heavy: bool) -> void:
	if attack_cd > 0.0 or attacking or dodge_t > 0.0:
		return
	attacking = true
	attack_cd = 1.1 if heavy else 0.45
	var tw := create_tween()
	if heavy:
		tw.tween_property(arm_r, "rotation:x", 2.9, 0.35)             # preparação lenta
		tw.tween_callback(_hit.bind(2.2, 3.2, 7.0))
		tw.tween_property(arm_r, "rotation:x", 0.3, 0.1)              # golpe
		tw.tween_interval(0.3)                                        # recuperação
	else:
		tw.tween_property(arm_r, "rotation:x", 2.2, 0.08)
		tw.tween_callback(_hit.bind(1.0, 2.6, 3.0))
		tw.tween_property(arm_r, "rotation:x", 0.3, 0.12)
	tw.tween_callback(func(): attacking = false)

func _hit(mult: float, reach: float, kb: float) -> void:
	var fwd := Vector3(0, 0, -1).rotated(Vector3.UP, facing)
	var dmg: float = GameState.attack_damage() * mult
	var min_dot: float = 0.2 if mult < 1.5 else -0.1
	for e in get_tree().get_nodes_in_group("enemies"):
		var to: Vector3 = (e as Node3D).global_position - global_position
		to.y = 0
		var d: float = to.length()
		if d < reach and (d < 0.5 or fwd.dot(to.normalized()) > min_dot):
			e.call("take_damage", dmg, to.normalized() * kb)

func dodge() -> void:
	if dodge_t > 0.0 or attacking or dodge_cd > 0.0:
		return
	dodge_cd = 0.8
	dodge_t = DODGE_TIME
	invuln = DODGE_TIME + 0.1
	if last_dir.length() > 0.1:
		dodge_dir = last_dir
	else:
		dodge_dir = Vector3(0, 0, -1).rotated(Vector3.UP, facing)

func interact() -> void:
	for n in get_tree().get_nodes_in_group("npcs"):
		if (n as Node3D).global_position.distance_to(global_position) < 3.5:
			GameState.notify.emit(str(n.call("interact")))
			return
	GameState.notify.emit("Nada por perto.")

func take_damage(amount: float) -> void:
	if invuln > 0.0:
		return
	hp -= amount
	if hp <= 0.0:
		GameState.notify.emit("Você desmaiou e voltou ao ponto inicial.")
		_respawn()

func _respawn() -> void:
	hp = max_hp
	velocity = Vector3.ZERO
	global_position = spawn_pos

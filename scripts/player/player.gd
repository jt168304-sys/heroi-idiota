extends CharacterBody3D
## Jogador em terceira pessoa. Modelo = PLACEHOLDER feito com primitivas (não é o modelo final).

const MeshUtil = preload("res://scripts/core/mesh_util.gd")
const GRAVITY := 20.0
const JUMP_VELOCITY := 7.0

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
var spawn_pos: Vector3 = Vector3(0, 0.5, 8)

var pivot: Node3D
var arm: SpringArm3D
var body: Node3D
var sword: MeshInstance3D

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

func _build_visual() -> void:
	body = Node3D.new()
	add_child(body)
	var dark := Color(0.12, 0.12, 0.15)
	MeshUtil.add(body, MeshUtil.capsule(0.3, 1.0), dark, Vector3(0, 1.05, 0))          # torso/jaqueta
	MeshUtil.add(body, MeshUtil.sphere(0.22), Color(0.95, 0.8, 0.7), Vector3(0, 1.68, 0)) # cabeça
	MeshUtil.add(body, MeshUtil.sphere(0.24), Color(0.05, 0.05, 0.07), Vector3(0, 1.74, 0.03), Vector3(1, 0.8, 1)) # cabelo
	MeshUtil.add(body, MeshUtil.cyl(0.27, 0.27, 0.1), Color(0.75, 0.1, 0.12), Vector3(0, 1.42, 0)) # cachecol vermelho
	MeshUtil.add(body, MeshUtil.box(Vector3(0.18, 0.7, 0.2)), dark, Vector3(-0.12, 0.35, 0)) # perna E
	MeshUtil.add(body, MeshUtil.box(Vector3(0.18, 0.7, 0.2)), dark, Vector3(0.12, 0.35, 0))  # perna D
	sword = MeshUtil.add(body, MeshUtil.box(Vector3(0.06, 0.9, 0.06)), Color(0.75, 0.75, 0.8), Vector3(0.42, 1.0, -0.3))

func apply_state() -> void:
	max_hp = GameState.max_hp()
	speed = GameState.move_speed()
	hp = minf(hp, max_hp)

func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_F:
			attack()
		elif e.keycode == KEY_E:
			interact()
		elif e.keycode == KEY_SPACE:
			jump_request = true

func _physics_process(delta: float) -> void:
	attack_cd = maxf(0.0, attack_cd - delta)
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
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if is_on_floor():
		velocity.y = JUMP_VELOCITY if jump_request else -0.1
	else:
		velocity.y -= GRAVITY * delta
	jump_request = false
	move_and_slide()

	if dir.length() > 0.1:
		facing = lerp_angle(facing, atan2(-dir.x, -dir.z), 12.0 * delta)
		body.rotation.y = facing

	pivot.global_position = global_position + Vector3(0, 1.5, 0)
	pivot.rotation = Vector3(pitch, yaw, 0)
	if global_position.y < -20.0:
		_respawn()

func attack() -> void:
	if attack_cd > 0.0:
		return
	attack_cd = 0.5
	var tw := create_tween()
	tw.tween_property(sword, "rotation:x", -1.6, 0.1)
	tw.tween_property(sword, "rotation:x", 0.0, 0.2)
	var fwd := Vector3(0, 0, -1).rotated(Vector3.UP, facing)
	var dmg: float = GameState.attack_damage()
	for e in get_tree().get_nodes_in_group("enemies"):
		var to: Vector3 = (e as Node3D).global_position - global_position
		to.y = 0
		var d: float = to.length()
		if d < 2.6 and (d < 0.5 or fwd.dot(to.normalized()) > 0.2):
			e.call("take_damage", dmg)

func interact() -> void:
	for n in get_tree().get_nodes_in_group("npcs"):
		if (n as Node3D).global_position.distance_to(global_position) < 3.5:
			GameState.notify.emit(str(n.call("interact")))
			return
	GameState.notify.emit("Nada por perto.")

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		GameState.notify.emit("Você desmaiou e voltou ao ponto inicial.")
		_respawn()

func _respawn() -> void:
	hp = max_hp
	velocity = Vector3.ZERO
	global_position = spawn_pos

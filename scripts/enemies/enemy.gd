extends CharacterBody3D
## Inimigo básico (lobo PLACEHOLDER). Valores vêm de data/enemies/enemies.json.

const MeshUtil = preload("res://scripts/core/mesh_util.gd")
const GRAVITY := 20.0

@export var enemy_type: String = "lobo"
var hp: float = 30.0
var damage: float = 6.0
var xp_reward: int = 30
var speed: float = 3.0
var _cd: float = 0.0
var _player
var _vis: Node3D

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1
	var def: Dictionary = GameState.enemy_defs.get(enemy_type, {})
	hp = float(def.get("vida", hp))
	damage = float(def.get("dano", damage))
	xp_reward = int(def.get("xp", xp_reward))
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.0
	col.shape = cap
	col.position.y = 0.5
	add_child(col)
	_vis = Node3D.new()
	add_child(_vis)
	var fur := Color(0.35, 0.33, 0.35)
	MeshUtil.add(_vis, MeshUtil.box(Vector3(0.5, 0.5, 1.1)), fur, Vector3(0, 0.55, 0))
	MeshUtil.add(_vis, MeshUtil.box(Vector3(0.4, 0.4, 0.4)), fur, Vector3(0, 0.75, -0.7))
	MeshUtil.add(_vis, MeshUtil.sphere(0.05), Color(0.9, 0.1, 0.1), Vector3(0.1, 0.82, -0.92))
	MeshUtil.add(_vis, MeshUtil.sphere(0.05), Color(0.9, 0.1, 0.1), Vector3(-0.1, 0.82, -0.92))
	var lbl := Label3D.new()
	lbl.text = "Lobo (provisório)"
	lbl.position = Vector3(0, 1.6, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.pixel_size = 0.006
	add_child(lbl)

func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.1
	var to: Vector3 = _player.global_position - global_position
	to.y = 0
	var d: float = to.length()
	if d < 12.0 and d > 1.6:
		var dir := to.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		_vis.rotation.y = atan2(-dir.x, -dir.z)
	else:
		velocity.x = 0
		velocity.z = 0
	if d <= 1.8:
		_cd -= delta
		if _cd <= 0.0:
			_player.take_damage(damage)
			_cd = 1.2
	else:
		_cd = 0.4
	move_and_slide()

func take_damage(amount: float) -> void:
	hp -= amount
	var tw := create_tween()
	tw.tween_property(_vis, "scale", Vector3(1.2, 0.8, 1.2), 0.05)
	tw.tween_property(_vis, "scale", Vector3.ONE, 0.1)
	if hp <= 0.0:
		GameState.notify.emit("%s derrotado! +%d XP" % [enemy_type.capitalize(), xp_reward])
		GameState.add_xp(xp_reward)
		GameState.on_enemy_killed(enemy_type)
		remove_from_group("enemies")
		queue_free()

extends StaticBody3D
## NPC de teste (placeholder). Entrega a missão de teste. Nome/diálogo definitivos: pendentes.

const MeshUtil = preload("res://scripts/core/mesh_util.gd")
@export var quest_id: String = "quest_teste_lobo"

func _ready() -> void:
	add_to_group("npcs")
	collision_layer = 1
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.7
	col.shape = cap
	col.position.y = 0.85
	add_child(col)
	MeshUtil.add(self, MeshUtil.capsule(0.35, 1.5), Color(0.85, 0.7, 0.2), Vector3(0, 0.85, 0))
	MeshUtil.add(self, MeshUtil.sphere(0.22), Color(0.95, 0.8, 0.7), Vector3(0, 1.75, 0))
	var lbl := Label3D.new()
	lbl.text = "NPC (provisório)"
	lbl.position = Vector3(0, 2.3, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.pixel_size = 0.006
	add_child(lbl)

func interact() -> String:
	return GameState.interact_quest(quest_id)

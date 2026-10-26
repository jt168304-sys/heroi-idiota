extends Node
## Dez slots de salvamento independentes em user://saves (persistem após fechar o app).

const SLOTS := 10
const DIR := "user://saves"

func _path(slot: int) -> String:
	return "%s/slot_%02d.json" % [DIR, slot]

func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(_path(slot))

func _read(slot: int) -> Dictionary:
	if slot < 1 or slot > SLOTS or not has_slot(slot):
		return {}
	var f := FileAccess.open(_path(slot), FileAccess.READ)
	if f == null:
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}

func slot_summary(slot: int) -> String:
	var d := _read(slot)
	if d.is_empty():
		return "Slot %d - vazio" % slot
	var cname := "?"
	if GameState.classes.has(d.get("classe", "")):
		cname = str(GameState.classes[d["classe"]]["nome"])
	return "Slot %d - %s Nv %d" % [slot, cname, int(d.get("nivel", 1))]

func save_slot(slot: int) -> Error:
	if slot < 1 or slot > SLOTS:
		return ERR_INVALID_PARAMETER
	var err := DirAccess.make_dir_recursive_absolute(DIR)
	if err != OK:
		return err
	var data: Dictionary = GameState.serialize()
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var p: Vector3 = player.global_position
		data["posicao"] = [p.x, p.y, p.z]
		data["hp"] = player.hp
	var tmp := _path(slot) + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(data))
	f.close()
	return DirAccess.rename_absolute(tmp, _path(slot))

func load_slot(slot: int) -> bool:
	var d := _read(slot)
	if d.is_empty() or not GameState.deserialize(d):
		return false
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var pos: Variant = d.get("posicao")
		if pos is Array and pos.size() == 3:
			player.global_position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
			player.velocity = Vector3.ZERO
		player.apply_state()
		player.hp = clampf(float(d.get("hp", player.max_hp)), 1.0, player.max_hp)
	return true

func delete_slot(slot: int) -> void:
	if has_slot(slot):
		DirAccess.remove_absolute(_path(slot))

extends Node
## Estado global da partida (autoload). Cálculos de progressão centralizados aqui.

signal changed
signal level_up(new_level: int)
signal notify(text: String)

const SAVE_VERSION := 1
const XP_BASE := 40
const POINTS_PER_LEVEL := 3

var classes: Dictionary = {}
var items: Dictionary = {}
var quest_defs: Dictionary = {}
var enemy_defs: Dictionary = {}

var class_id: String = ""
var level: int = 1
var xp: int = 0
var attr_points: int = 0
var attributes: Dictionary = {"forca": 5, "velocidade": 5, "vitalidade": 5}
var inventory: Dictionary = {}   # item_id -> quantidade
var quests: Dictionary = {}      # quest_id -> {"estado": String, "progresso": int}
var time_of_day: float = 0.15    # 0..1 (ver TimeSystem)

func _ready() -> void:
	classes = _index(_load_json("res://data/classes/classes.json"))
	items = _index(_load_json("res://data/items/items.json"))
	quest_defs = _index(_load_json("res://data/quests/quests.json"))
	enemy_defs = _index(_load_json("res://data/enemies/enemies.json"))

func _load_json(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("Arquivo de dados ausente: " + path)
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data is Array:
		return data
	push_error("JSON inválido: " + path)
	return []

func _index(arr: Array) -> Dictionary:
	var d: Dictionary = {}
	for e in arr:
		if e is Dictionary and e.has("id"):
			d[e["id"]] = e
	return d

# ---------- Progressão (fórmulas fáceis de alterar) ----------
func xp_to_next() -> int:
	return XP_BASE * level + 10 * level * level

func max_hp() -> float:
	return 80.0 + float(attributes.get("vitalidade", 5)) * 4.0

func move_speed() -> float:
	return 4.0 + float(attributes.get("velocidade", 5)) * 0.2

func attack_damage() -> float:
	return 8.0 + float(attributes.get("forca", 5)) * 2.0

func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		attr_points += POINTS_PER_LEVEL
		level_up.emit(level)
		notify.emit("Nível %d! +%d pontos de atributo" % [level, POINTS_PER_LEVEL])
	changed.emit()

func spend_point(attr: String) -> bool:
	if attr_points > 0 and attributes.has(attr):
		attr_points -= 1
		attributes[attr] = int(attributes[attr]) + 1
		changed.emit()
		return true
	return false

func apply_class(id: String) -> void:
	if not classes.has(id):
		return
	var c: Dictionary = classes[id]
	class_id = id
	level = 1
	xp = 0
	attr_points = 0
	attributes = (c["atributos"] as Dictionary).duplicate()
	inventory = {}
	quests = {}
	for item_id in c.get("equipamentos_iniciais", []):
		add_item(str(item_id), 1)
	changed.emit()

func class_name_text() -> String:
	if classes.has(class_id):
		return str(classes[class_id]["nome"])
	return "Sem classe"

# ---------- Inventário ----------
func add_item(id: String, qty: int = 1) -> void:
	inventory[id] = int(inventory.get(id, 0)) + qty
	changed.emit()

func remove_item(id: String, qty: int = 1) -> bool:
	if int(inventory.get(id, 0)) < qty:
		return false
	inventory[id] = int(inventory[id]) - qty
	if int(inventory[id]) <= 0:
		inventory.erase(id)
	changed.emit()
	return true

func item_name(id: String) -> String:
	if items.has(id):
		return str(items[id]["nome"])
	return id

func item_icon(id: String) -> String:
	if items.has(id):
		return str(items[id].get("icone", ""))
	return ""

# ---------- Missões ----------
func on_enemy_killed(enemy_type: String) -> void:
	for qid in quests.keys():
		var q: Dictionary = quests[qid]
		var def: Dictionary = quest_defs.get(qid, {})
		if q["estado"] == "ativa" and def.get("tipo", "") == "matar" and def.get("alvo", "") == enemy_type:
			q["progresso"] = int(q["progresso"]) + 1
			if int(q["progresso"]) >= int(def["quantidade"]):
				q["estado"] = "pronta"
				notify.emit("Objetivo cumprido! Volte ao NPC.")
	changed.emit()

func interact_quest(qid: String) -> String:
	if not quest_defs.has(qid):
		return "..."
	var def: Dictionary = quest_defs[qid]
	if not quests.has(qid):
		quests[qid] = {"estado": "ativa", "progresso": 0}
		changed.emit()
		return "Missão aceita: " + str(def["objetivo"])
	var q: Dictionary = quests[qid]
	match str(q["estado"]):
		"ativa":
			return "Progresso: %d/%d" % [int(q["progresso"]), int(def["quantidade"])]
		"pronta":
			q["estado"] = "concluida"
			var rew: Dictionary = def.get("recompensa", {})
			for iid in rew.get("itens", {}).keys():
				add_item(str(iid), int(rew["itens"][iid]))
			add_xp(int(rew.get("xp", 0)))
			return "Missão concluída!"
		_:
			return "Obrigado pela ajuda."

# ---------- Serialização ----------
func serialize() -> Dictionary:
	return {
		"versao": SAVE_VERSION,
		"classe": class_id,
		"nivel": level,
		"xp": xp,
		"pontos_atributo": attr_points,
		"atributos": attributes,
		"inventario": inventory,
		"missoes": quests,
		"hora_do_dia": time_of_day,
	}

func deserialize(d: Dictionary) -> bool:
	if int(d.get("versao", 0)) != SAVE_VERSION:
		return false
	if not (d.get("atributos") is Dictionary and d.get("inventario") is Dictionary and d.get("missoes") is Dictionary):
		return false
	var cid: String = str(d.get("classe", ""))
	if cid != "" and not classes.has(cid):
		return false
	class_id = cid
	level = maxi(1, int(d.get("nivel", 1)))
	xp = maxi(0, int(d.get("xp", 0)))
	attr_points = maxi(0, int(d.get("pontos_atributo", 0)))
	attributes = {}
	for k in d["atributos"].keys():
		attributes[str(k)] = int(d["atributos"][k])
	inventory = {}
	for k in d["inventario"].keys():
		inventory[str(k)] = int(d["inventario"][k])
	quests = {}
	for k in d["missoes"].keys():
		var q: Dictionary = d["missoes"][k]
		quests[str(k)] = {"estado": str(q.get("estado", "ativa")), "progresso": int(q.get("progresso", 0))}
	time_of_day = clampf(float(d.get("hora_do_dia", 0.15)), 0.0, 0.9999)
	changed.emit()
	return true

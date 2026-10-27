extends CanvasLayer
## HUD, botões de ação, menu (inventário/atributos/salvamento) e roleta de classe.

var player
var touch
var info: Label
var quest_label: Label
var msg: Label
var menu: PanelContainer
var inv_box: VBoxContainer
var attr_label: Label
var menu_status: Label
var slot_opt: OptionButton
var roulette: PanelContainer
var roul_label: Label
var roul_btn: Button
var _spun: bool = false
var _msg_t: float = 0.0

func _lbl(size_px: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	return l

func _btn(text: String, min_size: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", 22)
	b.focus_mode = Control.FOCUS_NONE
	b.button_down.connect(cb)
	return b

func setup(p) -> void:
	player = p
	touch = load("res://scripts/ui/touch_controls.gd").new()
	touch.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(touch)
	player.touch = touch

	var portrait := TextureRect.new()
	var ptex: Texture2D = load("res://assets/ui/portraits/heroi.png")
	if ptex != null:
		portrait.texture = ptex
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.custom_minimum_size = Vector2(80, 80)
	portrait.size = Vector2(80, 80)
	portrait.position = Vector2(16, 12)
	add_child(portrait)
	info = _lbl(22)
	info.position = Vector2(106, 14)
	add_child(info)
	quest_label = _lbl(20)
	quest_label.position = Vector2(20, 104)
	add_child(quest_label)
	msg = _lbl(26)
	msg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	msg.offset_top = 130
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(msg)
	GameState.notify.connect(_show_msg)

	# Botões de ação distribuídos em arco, para o polegar direito
	var layout := [
		["Atacar", 150, 30, 30, func(): player.attack()],
		["Pular", 110, 45, 200, func(): player.jump_request = true],
		["Esquiva", 110, 205, 40, func(): player.dodge()],
		["Pesado", 120, 215, 160, func(): player.attack_heavy()],
		["Interagir", 100, 350, 130, func(): player.interact()],
	]
	for it in layout:
		var bt := _btn(it[0], Vector2(it[1], it[1]), it[4])
		bt.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		bt.offset_right = -float(it[2])
		bt.offset_bottom = -float(it[3])
		bt.offset_left = bt.offset_right - float(it[1])
		bt.offset_top = bt.offset_bottom - float(it[1])
		bt.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		bt.grow_vertical = Control.GROW_DIRECTION_BEGIN
		add_child(bt)
		touch.buttons.append(bt)

	var mb := _btn("Menu", Vector2(120, 64), func(): _open_menu())
	mb.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mb.offset_left = -140
	mb.offset_right = -20
	mb.offset_top = 20
	mb.offset_bottom = 84
	add_child(mb)
	touch.buttons.append(mb)

	_build_menu()
	_build_roulette()
	if GameState.class_id == "":
		_open_roulette()

func _show_msg(t: String) -> void:
	msg.text = t
	_msg_t = 3.0

func _process(delta: float) -> void:
	if player == null:
		return
	info.text = "%s  Nv %d  XP %d/%d  HP %d/%d  Pts %d" % [GameState.class_name_text(), GameState.level, GameState.xp, GameState.xp_to_next(), int(player.hp), int(player.max_hp), GameState.attr_points]
	var qt := ""
	for qid in GameState.quests.keys():
		var q: Dictionary = GameState.quests[qid]
		var def: Dictionary = GameState.quest_defs.get(qid, {})
		if q["estado"] != "concluida":
			qt += "Missão: %s (%d/%d)\n" % [def.get("objetivo", qid), int(q["progresso"]), int(def.get("quantidade", 1))]
	quest_label.text = qt
	if _msg_t > 0.0:
		_msg_t -= delta
		if _msg_t <= 0.0:
			msg.text = ""

# ---------- Menu ----------
func _build_menu() -> void:
	menu = PanelContainer.new()
	menu.visible = false
	menu.custom_minimum_size = Vector2(640, 440)
	menu.set_anchors_preset(Control.PRESET_CENTER)
	menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	menu.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(menu)
	var v := VBoxContainer.new()
	menu.add_child(v)
	var title := Label.new()
	title.text = "Menu"
	title.add_theme_font_size_override("font_size", 28)
	v.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 170)
	v.add_child(scroll)
	inv_box = VBoxContainer.new()
	inv_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(inv_box)
	attr_label = Label.new()
	attr_label.add_theme_font_size_override("font_size", 18)
	v.add_child(attr_label)
	var attrs := HBoxContainer.new()
	v.add_child(attrs)
	for a in ["forca", "velocidade", "vitalidade"]:
		attrs.add_child(_btn("+ " + a.capitalize(), Vector2(190, 56), func():
			GameState.spend_point(a)
			player.apply_state()
			_refresh_menu()))
	slot_opt = OptionButton.new()
	slot_opt.add_theme_font_size_override("font_size", 20)
	v.add_child(slot_opt)
	var row := HBoxContainer.new()
	v.add_child(row)
	row.add_child(_btn("Salvar", Vector2(190, 56), func(): _do_save()))
	row.add_child(_btn("Carregar", Vector2(190, 56), func(): _do_load()))
	row.add_child(_btn("Fechar", Vector2(190, 56), func(): _close_menu()))
	menu_status = Label.new()
	v.add_child(menu_status)

func _refresh_menu() -> void:
	for c in inv_box.get_children():
		c.queue_free()
	if GameState.inventory.is_empty():
		var empty := Label.new()
		empty.text = "Inventário vazio"
		inv_box.add_child(empty)
	for id in GameState.inventory.keys():
		var row := HBoxContainer.new()
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(44, 44)
		var path: String = GameState.item_icon(str(id))
		if path != "" and ResourceLoader.exists(path):
			icon.texture = load(path)
		row.add_child(icon)
		var l := Label.new()
		l.text = "  %s x%d" % [GameState.item_name(str(id)), int(GameState.inventory[id])]
		l.add_theme_font_size_override("font_size", 20)
		row.add_child(l)
		inv_box.add_child(row)
	attr_label.text = "Atributos: " + str(GameState.attributes) + "   Pontos: " + str(GameState.attr_points)
	var sel := slot_opt.selected
	slot_opt.clear()
	for i in range(1, SaveManager.SLOTS + 1):
		slot_opt.add_item(SaveManager.slot_summary(i))
	slot_opt.selected = maxi(sel, 0)

func _open_menu() -> void:
	_refresh_menu()
	menu.visible = true
	touch.enabled = false

func _close_menu() -> void:
	menu.visible = false
	touch.enabled = true

func _do_save() -> void:
	var err := SaveManager.save_slot(slot_opt.selected + 1)
	menu_status.text = "Salvo." if err == OK else "Erro ao salvar (código %d)." % err
	_refresh_menu()

func _do_load() -> void:
	var ok := SaveManager.load_slot(slot_opt.selected + 1)
	menu_status.text = "Carregado." if ok else "Slot vazio ou arquivo inválido."
	_refresh_menu()

# ---------- Roleta ----------
func _build_roulette() -> void:
	roulette = PanelContainer.new()
	roulette.visible = false
	roulette.custom_minimum_size = Vector2(620, 300)
	roulette.set_anchors_preset(Control.PRESET_CENTER)
	roulette.grow_horizontal = Control.GROW_DIRECTION_BOTH
	roulette.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(roulette)
	var v := VBoxContainer.new()
	roulette.add_child(v)
	var t := Label.new()
	t.text = "Roleta de classe (classes de teste)"
	t.add_theme_font_size_override("font_size", 26)
	v.add_child(t)
	roul_label = Label.new()
	roul_label.add_theme_font_size_override("font_size", 30)
	roul_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	roul_label.custom_minimum_size = Vector2(560, 120)
	v.add_child(roul_label)
	roul_btn = _btn("Girar roleta", Vector2(260, 70), func(): _on_roul_btn())
	v.add_child(roul_btn)

func _open_roulette() -> void:
	_spun = false
	roul_label.text = "Toque para girar."
	roul_btn.text = "Girar roleta"
	roulette.visible = true
	touch.enabled = false

func _on_roul_btn() -> void:
	if _spun:
		roulette.visible = false
		touch.enabled = true
		return
	_spin()

func _spin() -> void:
	roul_btn.disabled = true
	var ids: Array = GameState.classes.keys()
	var t := 0.0
	var delay := 0.05
	while t < 2.0:
		roul_label.text = str(GameState.classes[ids.pick_random()]["nome"])
		await get_tree().create_timer(delay).timeout
		t += delay
		delay *= 1.08
	var pick: String = ids.pick_random()
	GameState.apply_class(pick)
	player.apply_state()
	player.hp = player.max_hp
	roul_label.text = "%s\n%s" % [GameState.classes[pick]["nome"], GameState.classes[pick]["descricao"]]
	_spun = true
	roul_btn.text = "Continuar"
	roul_btn.disabled = false

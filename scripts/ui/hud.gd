extends CanvasLayer
## HUD, botões de ação, menu (inventário/atributos/salvamento) e roleta de classe.

var player
var touch
var info: Label
var quest_label: Label
var msg: Label
var menu: PanelContainer
var inv_label: Label
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
	b.button_down.connect(cb)
	return b

func setup(p) -> void:
	player = p
	touch = load("res://scripts/ui/touch_controls.gd").new()
	touch.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(touch)
	player.touch = touch

	info = _lbl(22)
	info.position = Vector2(20, 14)
	add_child(info)
	quest_label = _lbl(20)
	quest_label.position = Vector2(20, 84)
	add_child(quest_label)
	msg = _lbl(26)
	msg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	msg.offset_top = 130
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(msg)
	GameState.notify.connect(_show_msg)

	# Botões de ação (canto inferior direito)
	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_theme_constant_override("margin_right", 30)
	mc.add_theme_constant_override("margin_bottom", 30)
	add_child(mc)
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_horizontal = Control.SIZE_SHRINK_END
	box.size_flags_vertical = Control.SIZE_SHRINK_END
	mc.add_child(box)
	var sz := Vector2(130, 130)
	for b in [
		_btn("Interagir", sz, func(): player.interact()),
		_btn("Pular", sz, func(): player.jump_request = true),
		_btn("Atacar", sz, func(): player.attack()),
	]:
		box.add_child(b)
		touch.buttons.append(b)

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
	inv_label = Label.new()
	inv_label.add_theme_font_size_override("font_size", 20)
	v.add_child(inv_label)
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
	var t := "Inventário:\n"
	if GameState.inventory.is_empty():
		t += "  (vazio)\n"
	for id in GameState.inventory.keys():
		t += "  - %s x%d\n" % [GameState.item_name(str(id)), int(GameState.inventory[id])]
	t += "Atributos: " + str(GameState.attributes) + "   Pontos: " + str(GameState.attr_points)
	inv_label.text = t
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

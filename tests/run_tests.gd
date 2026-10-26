extends SceneTree
## Testes de dados e salvamento (sem cena 3D). Execute:
##   godot --headless --path . -s tests/run_tests.gd
## NÃO VERIFICADO: escrito sem acesso ao Godot.

var _fails: int = 0

func _check(cond: bool, name: String) -> void:
	print(("OK    " if cond else "FALHA ") + name)
	if not cond:
		_fails += 1

func _initialize() -> void:
	var gs = root.get_node("GameState")
	var sm = root.get_node("SaveManager")
	_check(gs.classes.size() > 0, "classes carregadas")
	_check(gs.items.size() > 0, "itens carregados")
	_check(gs.quest_defs.has("quest_teste_lobo"), "missão de teste carregada")
	gs.apply_class(gs.classes.keys()[0])
	_check(gs.class_id != "", "classe aplicada")
	gs.add_xp(10000)
	_check(gs.level > 1, "subida de nível")
	gs.add_item("pocao_cura", 3)
	gs.interact_quest("quest_teste_lobo")
	gs.on_enemy_killed("lobo")
	_check(gs.quests["quest_teste_lobo"]["estado"] == "pronta", "missão pronta após abate")
	var lvl: int = gs.level
	_check(sm.save_slot(10) == OK, "salvar slot 10")
	gs.level = 1
	gs.inventory = {}
	_check(sm.load_slot(10), "carregar slot 10")
	_check(gs.level == lvl and gs.inventory.get("pocao_cura", 0) == 3, "dados restaurados")
	sm.delete_slot(10)
	print("Falhas: ", _fails)
	quit(1 if _fails > 0 else 0)

extends Node3D
## Monta a primeira região jogável: mundo, jogador, NPC, inimigo e interface.

func _ready() -> void:
	var world = load("res://scripts/world/world_builder.gd").new()
	world.name = "Mundo"
	add_child(world)

	var player = load("res://scripts/player/player.gd").new()
	player.name = "Jogador"
	player.position = world.spawn_point
	player.spawn_pos = world.spawn_point
	add_child(player)

	var npc: StaticBody3D = load("res://scripts/world/npc.gd").new()
	npc.position = Vector3(-4, 0, 3)
	add_child(npc)

	var wolf: CharacterBody3D = load("res://scripts/enemies/enemy.gd").new()
	wolf.position = Vector3(9, 0.2, -12)
	add_child(wolf)

	var hud = load("res://scripts/ui/hud.gd").new()
	add_child(hud)
	hud.setup(player)

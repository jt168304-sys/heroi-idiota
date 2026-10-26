extends Node3D
## Constrói a região florestal inicial (provisória) com primitivas reutilizadas.

const MeshUtil = preload("res://scripts/core/mesh_util.gd")
var spawn_point: Vector3 = Vector3(0, 0.5, 8)

func _ready() -> void:
	_build_env()
	_build_ground()
	_build_trees()
	_build_rocks()
	_build_props()

func _build_env() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)
	var ts = load("res://scripts/world/time_system.gd").new()
	ts.sun = sun
	ts.env = env
	add_child(ts)

func _solid(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.position = pos
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	sb.add_child(cs)
	MeshUtil.add(sb, MeshUtil.box(size), color)
	add_child(sb)
	return sb

func _build_ground() -> void:
	var g := StaticBody3D.new()
	g.collision_layer = 1
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(80, 1, 80)
	cs.shape = bs
	cs.position.y = -0.5
	g.add_child(cs)
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	MeshUtil.add(g, pm, Color(0.25, 0.5, 0.2))  # TEMPORÁRIO: cor no lugar da textura de grama
	var path_a := PlaneMesh.new()
	path_a.size = Vector2(3, 40)
	MeshUtil.add(g, path_a, Color(0.45, 0.32, 0.2), Vector3(0, 0.02, -5))
	var path_b := PlaneMesh.new()
	path_b.size = Vector2(22, 3)
	MeshUtil.add(g, path_b, Color(0.45, 0.32, 0.2), Vector3(10, 0.02, -12))
	add_child(g)
	# Paredes invisíveis nas bordas
	for p in [Vector3(0, 2, -40), Vector3(0, 2, 40)]:
		_wall(p, Vector3(80, 4, 1))
	for p in [Vector3(-40, 2, 0), Vector3(40, 2, 0)]:
		_wall(p, Vector3(1, 4, 80))

func _wall(pos: Vector3, size: Vector3) -> void:
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.position = pos
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	sb.add_child(cs)
	add_child(sb)

func _build_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var trunk := MeshUtil.cyl(0.25, 0.3, 2.0)
	var crown := MeshUtil.sphere(1.5)
	var cone := MeshUtil.cyl(0.0, 1.4, 3.5)
	var shape := CylinderShape3D.new()
	shape.radius = 0.35
	shape.height = 3.0
	var count := 0
	var tries := 0
	while count < 45 and tries < 400:
		tries += 1
		var x := rng.randf_range(-36, 36)
		var z := rng.randf_range(-36, 36)
		if absf(x) < 3.0 and z > -26.0 and z < 14.0:
			continue
		if z > -15.0 and z < -9.0 and x > -1.0 and x < 22.0:
			continue
		if Vector2(x, z).distance_to(Vector2(0, 8)) < 5.0:
			continue
		if Vector2(x, z).distance_to(Vector2(-4, 3)) < 3.0 or Vector2(x, z).distance_to(Vector2(9, -12)) < 4.0:
			continue
		var t := StaticBody3D.new()
		t.collision_layer = 1
		t.position = Vector3(x, 0, z)
		var s := rng.randf_range(0.8, 1.4)
		t.scale = Vector3(s, s, s)
		var cs := CollisionShape3D.new()
		cs.shape = shape
		cs.position.y = 1.5
		t.add_child(cs)
		MeshUtil.add(t, trunk, Color(0.35, 0.22, 0.12), Vector3(0, 1.0, 0))
		if count % 3 == 0:
			MeshUtil.add(t, cone, Color(0.1, 0.35, 0.2), Vector3(0, 3.7, 0))   # conífera
		else:
			MeshUtil.add(t, crown, Color(0.15, 0.5, 0.18), Vector3(0, 3.2, 0))  # folhas
		add_child(t)
		count += 1

func _build_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var rock := MeshUtil.sphere(0.6)
	var shape := SphereShape3D.new()
	shape.radius = 0.6
	for i in 18:
		var x := rng.randf_range(-30, 30)
		var z := rng.randf_range(-30, 30)
		if absf(x) < 3.5 or Vector2(x, z).distance_to(Vector2(9, -12)) < 5.0:
			continue
		var r := StaticBody3D.new()
		r.collision_layer = 1
		var s := rng.randf_range(0.5, 1.6)
		r.position = Vector3(x, 0.15 * s, z)
		r.scale = Vector3(s, s * 0.7, s)
		r.rotation.y = rng.randf() * TAU
		var cs := CollisionShape3D.new()
		cs.shape = shape
		r.add_child(cs)
		MeshUtil.add(r, rock, Color(0.45, 0.45, 0.47))
		add_child(r)

func _build_props() -> void:
	_solid(Vector3(-5, 0.45, 8), Vector3(0.9, 0.9, 0.9), Color(0.55, 0.38, 0.2))   # caixa
	_solid(Vector3(-5.2, 1.35, 8), Vector3(0.8, 0.8, 0.8), Color(0.5, 0.35, 0.18)) # caixa
	var barrel := _solid(Vector3(-6.3, 0.5, 8.4), Vector3(0.8, 1.0, 0.8), Color(0.4, 0.27, 0.15)) # barril
	barrel.rotation.y = 0.5
	_solid(Vector3(4, 0.3, 2), Vector3(0.9, 0.6, 0.6), Color(0.4, 0.25, 0.1))     # baú
	_solid(Vector3(2.0, 0.6, 11), Vector3(0.15, 1.2, 0.15), Color(0.4, 0.27, 0.15)) # placa (poste)
	var sign_lbl := Label3D.new()
	sign_lbl.text = "Floresta Inicial\n(provisório)"
	sign_lbl.position = Vector3(2.0, 1.5, 11)
	sign_lbl.pixel_size = 0.008
	add_child(sign_lbl)
	# Cerca
	for i in 5:
		_solid(Vector3(-9 + i * 1.2, 0.5, 12), Vector3(1.0, 1.0, 0.1), Color(0.5, 0.35, 0.2))
	# Barraca
	var tent := _solid(Vector3(-10, 1.0, -4), Vector3(3, 2, 3), Color(0.85, 0.75, 0.55))
	tent.get_child(1).mesh = _prism(Vector3(3, 2, 3))
	# Fogueira
	var fire := StaticBody3D.new()
	fire.position = Vector3(3.5, 0, -1)
	MeshUtil.add(fire, MeshUtil.cyl(0.35, 0.45, 0.2), Color(0.3, 0.3, 0.3), Vector3(0, 0.1, 0))
	var flame := MeshUtil.add(fire, MeshUtil.sphere(0.25), Color(1.0, 0.5, 0.1), Vector3(0, 0.4, 0))
	flame.material_override = flame.material_override.duplicate()
	flame.material_override.emission_enabled = true
	flame.material_override.emission = Color(1.0, 0.45, 0.05)
	var l := OmniLight3D.new()
	l.position = Vector3(0, 0.8, 0)
	l.light_color = Color(1.0, 0.6, 0.3)
	l.omni_range = 6.0
	fire.add_child(l)
	add_child(fire)

func _prism(size: Vector3) -> PrismMesh:
	var p := PrismMesh.new()
	p.size = size
	return p

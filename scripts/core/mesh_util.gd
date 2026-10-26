extends RefCounted
## Utilitário para criar malhas primitivas com materiais reutilizados (placeholders).

static var _cache: Dictionary = {}

static func mat(color: Color, rough: float = 0.9) -> StandardMaterial3D:
	var key: String = color.to_html() + str(rough)
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	_cache[key] = m
	return m

static func add(parent: Node, mesh: Mesh, color: Color, pos: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(color)
	mi.position = pos
	mi.scale = scl
	parent.add_child(mi)
	return mi

static func tex_mat(path: String, uv_scale: Vector3 = Vector3(1, 1, 1)) -> StandardMaterial3D:
	var key: String = "tex:" + path + str(uv_scale)
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	var t: Texture2D = load(path)
	if t != null:
		m.albedo_texture = t
	m.uv1_scale = uv_scale
	m.roughness = 1.0
	_cache[key] = m
	return m

static func add_mat(parent: Node, mesh: Mesh, material: Material, pos: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.scale = scl
	parent.add_child(mi)
	return mi

static func box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b

static func sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 12
	s.rings = 6
	return s

static func cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 10
	return c

static func capsule(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 12
	c.rings = 4
	return c

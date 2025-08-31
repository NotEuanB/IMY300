class_name SellPortal
extends Area2D

@export var unit_pool: UnitPool
@export var player_stats: PlayerStats

# Subtle hover glow tuning
@export var hover_border_color: Color = Color(1, 1, 1, 0.35)
@export var hover_fill_alpha: float = 0.04
@export var hover_border_thickness: float = 2.0
@export var hover_radius: float = 14.0
@export var hover_glow_size: float = 8.0
@export var hover_glow_strength: float = 0.25
@export var pulse_min_alpha: float = 0.08
@export var pulse_max_alpha: float = 0.18
@export var pulse_duration: float = 0.6
@export var hover_glow_offset: Vector2 = Vector2.ZERO
@export var show_side_bars: bool = false
@export var side_bar_height_factor: float = 0.7 # 0..1 of half height for side bars if enabled

@onready var gold: HBoxContainer = %Gold
@onready var gold_label: Label = %GoldLabel
@onready var hover_border: Line2D = $CollisionShape2D/HoverBorder
@onready var hover_glow: ColorRect = $CollisionShape2D/HoverGlow

var current_unit: Unit
var _glow_tween: Tween

func _ready() -> void:
	var units := get_tree().get_nodes_in_group("units")
	for unit: Unit in units:
		setup_unit(unit)
	_rebuild_hover_border()
	_setup_hover_glow()


func setup_unit(unit: Unit) -> void:
	unit.drag_and_drop.dropped.connect(_on_unit_dropped.bind(unit))


func _sell_unit(unit: Unit) -> void:
	player_stats.gold += unit.stats.gold_cost
	
	unit_pool.add_unit(unit.stats)
	
	unit.queue_free()


func _on_unit_dropped(_starting_position: Vector2, unit: Unit) -> void:
	if unit and unit == current_unit:
		_sell_unit(unit)

func _on_area_entered(unit: Unit) -> void:
	current_unit = unit
	gold_label.text = str(unit.stats.gold_cost)
	gold.show()
	# Prefer the prettier glow effect
	_show_hover_glow(true)


func _on_area_exited(unit: Unit) -> void:
	if unit and unit == current_unit:
		current_unit = null
	
	gold.hide()
	_show_hover_glow(false)

func _rebuild_hover_border() -> void:
	var shape: RectangleShape2D = $CollisionShape2D.shape
	if shape == null:
		return
	# Compute half-extents in LOCAL space. As a child of CollisionShape2D,
	# the Line2D will inherit the parent's scale automatically; don't apply it here.
	var ext: Vector2 = shape.size * 0.5
	hover_border.points = PackedVector2Array([
		Vector2(-ext.x, -ext.y), Vector2(ext.x, -ext.y),
		Vector2(ext.x, ext.y), Vector2(-ext.x, ext.y), Vector2(-ext.x, -ext.y)
	])

func _show_hover_border(show: bool) -> void:
	hover_border.visible = show

func _setup_hover_glow() -> void:
	# Rounded-rectangle glow shader sized to the collision rect (local space)
	var shape: RectangleShape2D = $CollisionShape2D.shape
	if shape == null:
		return
	var size_local: Vector2 = shape.size
	hover_glow.custom_minimum_size = size_local
	hover_glow.pivot_offset = size_local * 0.5
	hover_glow.position = -hover_glow.pivot_offset + hover_glow_offset

	var shader := Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 0.35);
	uniform float border_thickness = 2.0;
	uniform float radius = 14.0;
	uniform float glow_size = 8.0;
	uniform float glow_strength = 0.25;
	uniform vec2 rect_size;
	uniform int use_sides = 0; // 0/1 to include side bars
	uniform float side_height_factor = 0.7; // fraction of half height used for side bars

	float sdRoundRect(vec2 p, vec2 b, float r){
		vec2 q = abs(p) - b + vec2(r);
		return length(max(q, vec2(0.0))) - r;
	}

	void fragment(){
		// Local space centered at (0,0)
		vec2 p = UV * rect_size - 0.5 * rect_size;
		vec2 half_size = 0.5 * rect_size;

		// Build an upside-down U (∩) or only the top bar depending on use_sides
		vec2 c_left  = vec2(-half_size.x + 0.5 * border_thickness, 0.0);
		vec2 c_right = vec2( half_size.x - 0.5 * border_thickness, 0.0);
		vec2 c_top   = vec2(0.0, -half_size.y + 0.5 * border_thickness);

		vec2 h_top  = vec2(max(half_size.x - 0.5 * border_thickness, 0.0), 0.5 * border_thickness);
		float d_top   = sdRoundRect(p - c_top,   h_top,  radius);
		float d = d_top;
		if (use_sides == 1) {
			float side_h = max(half_size.y * side_height_factor - 0.5 * border_thickness, 0.0);
			vec2 h_side = vec2(0.5 * border_thickness, side_h);
			float d_left  = sdRoundRect(p - c_left,  h_side, radius);
			float d_right = sdRoundRect(p - c_right, h_side, radius);
			d = min(d, min(d_left, d_right));
		}

		// Stroke-only ring around the shape, no fill
		float border = 1.0 - smoothstep(border_thickness, border_thickness + 1.0, abs(d));
		// Soft outer glow only outside
		float glow = 1.0 - smoothstep(0.0, glow_size, max(d, 0.0));

		vec4 col = vec4(0.0);
		col += border_color * border;
		col += vec4(border_color.rgb, 1.0) * glow * glow_strength;
		COLOR = col;
	}
	"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("rect_size", size_local)
	# Apply tunable parameters from exports
	mat.set_shader_parameter("border_color", hover_border_color)
	mat.set_shader_parameter("border_thickness", hover_border_thickness)
	mat.set_shader_parameter("radius", hover_radius)
	mat.set_shader_parameter("glow_size", hover_glow_size)
	mat.set_shader_parameter("glow_strength", hover_glow_strength)
	mat.set_shader_parameter("use_sides", int(show_side_bars))
	mat.set_shader_parameter("side_height_factor", side_bar_height_factor)
	hover_glow.material = mat

func _show_hover_glow(show: bool) -> void:
	hover_glow.visible = show
	if not show:
		if is_instance_valid(_glow_tween):
			_glow_tween.kill()
		return
	# Pulse the alpha subtly
	hover_glow.modulate = Color(1, 1, 1, pulse_min_alpha)
	if is_instance_valid(_glow_tween):
		_glow_tween.kill()
	_glow_tween = create_tween()
	_glow_tween.set_loops()
	_glow_tween.tween_property(hover_glow, "modulate:a", pulse_max_alpha, pulse_duration).from(pulse_min_alpha)

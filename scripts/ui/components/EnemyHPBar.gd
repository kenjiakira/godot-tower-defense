extends Node2D

var bar: ProgressBar

func _ready():
	if bar == null:
		_create_bar()
	setup_style()


func initialize(max_hp: int):
	if bar == null:
		_create_bar()
	setup(max_hp)


func _create_bar():
	bar = ProgressBar.new()
	bar.name = "ProgressBar"
	bar.position = Vector2(-20, -35)
	bar.custom_minimum_size = Vector2(40, 6)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)


func setup(max_hp: int):
	if bar == null:
		_create_bar()
	bar.min_value = 0
	bar.max_value = max_hp
	bar.value = max_hp
	bar.show_percentage = false

func set_hp(value: int):
	if bar == null:
		_create_bar()
	bar.value = value
	
	var ratio = bar.value / bar.max_value
	
	var fill = bar.get_theme_stylebox("fill").duplicate()
	
	if ratio > 0.6:
		fill.bg_color = Color(0.25, 1.0, 0.25, 1.0)
	elif ratio > 0.3:
		fill.bg_color = Color(1.0, 0.85, 0.2, 1.0)
	else:
		fill.bg_color = Color(1.0, 0.25, 0.2, 1.0)
	
	bar.add_theme_stylebox_override("fill", fill)
func setup_style():
	if bar == null:
		_create_bar()
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.06, 0.05, 0.85)
	bg.border_width_left = 1
	bg.border_width_right = 1
	bg.border_width_top = 1
	bg.border_width_bottom = 1
	bg.border_color = Color(0.95, 0.75, 0.35, 1.0)
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3

	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.25, 1.0, 0.25, 1.0)
	fill.corner_radius_top_left = 2
	fill.corner_radius_top_right = 2
	fill.corner_radius_bottom_left = 2
	fill.corner_radius_bottom_right = 2

	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)

extends Node2D

signal destroyed

@export var max_hp := 10

var current_hp := 10
var original_position: Vector2
var original_modulate: Color

@onready var sprite: Sprite2D = $Sprite
@onready var hp_bar: ProgressBar = $HPBar

func _ready():
	original_position = position
	original_modulate = sprite.modulate
	setup(max_hp)

func setup(hp: int):
	max_hp = hp
	current_hp = hp

	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp

func take_damage(amount := 1):
	current_hp -= amount
	current_hp = max(current_hp, 0)

	update_hp_bar()
	play_hit_effect()

	if current_hp <= 0:
		destroyed.emit()

func update_hp_bar():
	if hp_bar:
		hp_bar.value = current_hp

func play_hit_effect():
	flash_red()
	shake()

func flash_red():
	sprite.modulate = Color(1, 0.25, 0.25)

	var tween = create_tween()
	tween.tween_property(sprite, "modulate", original_modulate, 0.18)

func shake():
	var tween = create_tween()

	tween.tween_property(self, "position", original_position + Vector2(8, 0), 0.04)
	tween.tween_property(self, "position", original_position + Vector2(-8, 0), 0.04)
	tween.tween_property(self, "position", original_position + Vector2(5, 0), 0.04)
	tween.tween_property(self, "position", original_position, 0.04)

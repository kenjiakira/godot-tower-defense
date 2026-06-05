extends Node

@export var floating_text_scene: PackedScene
@export var death_effect_scene: PackedScene
@export var effects_root: Node

func show_damage_text(world_pos: Vector2, damage: int, color: Color = Color.WHITE):
	if floating_text_scene == null:
		return

	var text = floating_text_scene.instantiate()
	var target_root = effects_root if effects_root != null else get_tree().current_scene
	target_root.add_child(text)
	text.global_position = world_pos + Vector2(-10, -35)
	text.setup_text("-" + str(damage), color)


func show_coin_text(world_pos: Vector2, amount: int, fly_target: Vector2):
	if floating_text_scene == null:
		return

	var text = floating_text_scene.instantiate()
	var target_root = effects_root if effects_root != null else get_tree().current_scene
	target_root.add_child(text)
	text.global_position = world_pos + Vector2(0, -45)
	text.setup_text("+" + str(amount) + "$", Color.GOLD)
	text.fly_to(fly_target)


func show_death_effect(world_pos: Vector2, enemy_color: Color, enemy_name: String):
	if death_effect_scene == null:
		return

	var effect = death_effect_scene.instantiate()
	var target_root = effects_root if effects_root != null else get_tree().current_scene
	target_root.add_child(effect)
	effect.global_position = world_pos

	if effect.has_method("set_color"):
		effect.set_color(enemy_color)

	if effect.has_method("set_enemy_type"):
		effect.set_enemy_type(enemy_name)


func play_camera_shake(amount: float):
	var cam = get_tree().get_first_node_in_group("main_camera")
	if cam and cam.has_method("shake"):
		cam.shake(amount)

extends PathFollow2D

@export var speed := 100.0
@export var max_hp := 100
@export var reward := 10
@export var enemy_color := Color.WHITE
@export var enemy_name := "Normal"

@export var floating_text_scene: PackedScene
@export var death_effect_scene: PackedScene
@export var hpbar_scene: PackedScene

var hp := 100
var has_reached_base := false
var is_dead := false
var hpbar = null

signal reached_base
signal died(reward, pos)


func _ready():
	rotates = false
	rotation = 0
	
	progress = 0
	hp = max_hp
	
	if has_node("Body"):
		$Body.rotation = 0
		$Body.modulate = enemy_color
	
	setup_hpbar()


func setup_hpbar():
	if hpbar_scene == null:
		print(enemy_name, " chưa gán hpbar_scene")
		return
	
	hpbar = hpbar_scene.instantiate()
	add_child(hpbar)
	
	hpbar.position = Vector2(0, 0)
	hpbar.rotation = 0
	hpbar.z_index = 100
	
	if hpbar.has_method("setup"):
		hpbar.setup(max_hp)
	else:
		print("EnemyHPBar chưa có hàm setup()")


func _process(delta):
	if has_reached_base or is_dead:
		return

	progress += speed * delta
	
	if progress_ratio >= 0.99:
		has_reached_base = true
		base_hit_effect()
		reached_base.emit()
		queue_free()


func base_hit_effect():
	var cam = get_tree().get_first_node_in_group("main_camera")
	if cam and cam.has_method("shake"):
		if enemy_name == "Boss":
			cam.shake(15)
		elif enemy_name == "Tank":
			cam.shake(10)
		else:
			cam.shake(6)


func take_damage(damage):
	if is_dead or has_reached_base:
		return
	
	hp -= damage
	
	if hpbar != null and hpbar.has_method("set_hp"):
		hpbar.set_hp(max(hp, 0))
	
	spawn_floating_text(damage)
	
	if hp <= 0:
		die()
	else:
		hit_flash()


func die():
	if is_dead:
		return
	
	is_dead = true
	
	spawn_death_effect()
	died.emit(reward, global_position)
	queue_free()


func spawn_floating_text(damage):
	if floating_text_scene == null:
		return
	
	var text = floating_text_scene.instantiate()
	get_tree().current_scene.add_child(text)
	text.global_position = global_position + Vector2(-10, -35)
	text.setup_text("-" + str(damage), Color.WHITE)


func spawn_death_effect():
	if death_effect_scene == null:
		return
	
	var effect = death_effect_scene.instantiate()
	get_tree().current_scene.add_child(effect)
	effect.global_position = global_position
	
	if effect.has_method("set_color"):
		effect.set_color(enemy_color)
	
	if effect.has_method("set_enemy_type"):
		effect.set_enemy_type(enemy_name)


func hit_flash():
	if not has_node("Body"):
		return
	
	$Body.modulate = Color.WHITE
	await get_tree().create_timer(0.08).timeout
	
	if is_instance_valid(self) and not is_dead and has_node("Body"):
		$Body.modulate = enemy_color

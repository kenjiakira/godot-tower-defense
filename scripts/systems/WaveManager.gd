extends Node

signal wave_started(current_wave)
signal wave_cleared
signal enemy_spawned(enemy)
signal enemy_died(reward, pos)
signal enemy_reached_base

@export var spawn_timer: Timer
@export var path_root: Node2D
@export var audio_manager: Node

var normal_scene: PackedScene
var fast_scene: PackedScene
var tank_scene: PackedScene
var boss_scene: PackedScene

var current_wave := 1
var enemies_to_spawn := 10
var enemies_spawned := 0
var enemies_alive := 0
var wave_in_progress := false
var scene_owner: Node


func setup(owner: Node, timer: Timer, path: Node2D, audio: Node):
	scene_owner = owner
	spawn_timer = timer
	path_root = path
	audio_manager = audio

	if spawn_timer:
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)


func set_enemy_scenes(normal: PackedScene, fast: PackedScene, tank: PackedScene, boss: PackedScene):
	normal_scene = normal
	fast_scene = fast
	tank_scene = tank
	boss_scene = boss


func start_wave(wave_num: int, total_to_spawn: int):
	current_wave = wave_num
	enemies_to_spawn = total_to_spawn
	enemies_spawned = 0
	enemies_alive = 0
	wave_in_progress = true

	if spawn_timer:
		spawn_timer.start()

	wave_started.emit(current_wave)


func stop_wave():
	wave_in_progress = false
	if spawn_timer:
		spawn_timer.stop()


func _on_spawn_timer_timeout():
	if not wave_in_progress:
		return

	var enemy_scene = _get_enemy_scene_for_wave()

	if enemy_scene == null:
		print("Enemy scene is not assigned")
		return

	if enemies_spawned >= enemies_to_spawn:
		spawn_timer.stop()
		return

	enemies_spawned += 1
	enemies_alive += 1

	var enemy = enemy_scene.instantiate()
	if path_root:
		path_root.add_child(enemy)

	if audio_manager and enemy.has_method("get"):
		audio_manager.play_enemy_spawn(enemy.enemy_name)

	enemy.reached_base.connect(_on_enemy_reached_base)
	enemy.died.connect(_on_enemy_died)
	enemy_spawned.emit(enemy)


func _get_enemy_scene_for_wave() -> PackedScene:
	if current_wave % 5 == 0:
		if enemies_spawned == enemies_to_spawn - 1:
			return boss_scene

	if current_wave <= 2:
		return normal_scene

	if current_wave <= 4:
		var r = randf()
		if r < 0.7:
			return normal_scene
		return fast_scene

	if current_wave <= 9:
		var r = randf()
		if r < 0.5:
			return normal_scene
		elif r < 0.8:
			return fast_scene
		return tank_scene

	var r = randf()
	if r < 0.4:
		return normal_scene
	elif r < 0.65:
		return fast_scene
	elif r < 0.9:
		return tank_scene

	return boss_scene


func _on_enemy_died(reward, pos):
	enemies_alive -= 1
	enemy_died.emit(reward, pos)
	_check_wave_end()


func _on_enemy_reached_base():
	enemies_alive -= 1
	enemy_reached_base.emit()
	_check_wave_end()


func _check_wave_end():
	if enemies_spawned >= enemies_to_spawn and enemies_alive <= 0:
		wave_in_progress = false
		wave_cleared.emit()


func reset():
	current_wave = 1
	enemies_to_spawn = 10
	enemies_spawned = 0
	enemies_alive = 0
	wave_in_progress = false

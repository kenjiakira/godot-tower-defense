extends Node

signal money_changed(value)
signal base_hp_changed(value)
signal wave_changed(value)
signal tower_selected(tower)
signal build_spot_selected(spot)
signal wave_state_changed(in_progress)
signal pause_changed(paused)
signal speed_changed(speed)

var money := 100:
	set(value):
		money = value
		money_changed.emit(money)

var base_hp := 10:
	set(value):
		base_hp = value
		base_hp_changed.emit(base_hp)

var wave := 1:
	set(value):
		wave = value
		wave_changed.emit(wave)

var selected_tower = null:
	set(value):
		selected_tower = value
		tower_selected.emit(selected_tower)

var pending_build_spot = null:
	set(value):
		pending_build_spot = value
		build_spot_selected.emit(pending_build_spot)

var wave_in_progress := false:
	set(value):
		wave_in_progress = value
		wave_state_changed.emit(wave_in_progress)

var is_paused := false:
	set(value):
		is_paused = value
		pause_changed.emit(is_paused)

var game_speed := 1.0:
	set(value):
		game_speed = value
		speed_changed.emit(game_speed)

func reset():
	money = 100
	base_hp = 10
	wave = 1
	selected_tower = null
	pending_build_spot = null
	wave_in_progress = false
	is_paused = false
	game_speed = 1.0

extends Node2D

@export var normal_enemy_scene: PackedScene
@export var fast_enemy_scene: PackedScene
@export var tank_enemy_scene: PackedScene
@export var boss_enemy_scene: PackedScene

@export var floating_text_scene: PackedScene

@onready var town_hall = $TownHall
@onready var audio_manager = $Managers/AudioManager
@onready var ui_manager = $Managers/UIManager
@onready var build_manager = $Managers/BuildManager
@onready var bgm_player = $SFX/BGMSound

var warning_tween: Tween
var wave_in_progress := false
var selected_tower = null

var money := 100
var base_hp := 10
var wave := 1

var is_paused := false
var sound_enabled := true
var game_speed := 1.0

var enemies_to_spawn := 10
var enemies_spawned := 0
var enemies_alive := 0

var pending_build_spot = null

const SOUND_ICON_ON = preload("res://assets/ui/right_topbar_icon/volume.png")
const SOUND_ICON_OFF = preload("res://assets/ui/right_topbar_icon/volume_disable.png")
const PAUSE_ICON_ON = preload("res://assets/ui/right_topbar_icon/pause.png")
const PAUSE_ICON_OFF = preload("res://assets/ui/right_topbar_icon/pause_disable.png")
const SPEED_ICON_1X = preload("res://assets/ui/right_topbar_icon/speed_1x.png")
const SPEED_ICON_2X = preload("res://assets/ui/right_topbar_icon/speed_2x.png")

const TOWER_COSTS = {
	0: 50,   # BASIC
	1: 70,   # AOE
	2: 100,  # SNIPER
	3: 60    # SLOW
}

const TOWER_NAMES = {
	0: "Basic",
	1: "AOE",
	2: "Sniper",
	3: "Slow"
}


func _ready():
	Engine.time_scale = 1.0
	get_tree().paused = false
	
	if not bgm_player.playing:
		bgm_player.play()
	
	ui_manager.setup()
	update_ui()
	setup_hp_bar_style()
	setup_tower_buttons()
	update_wave_button_state()
	
	$SpawnTimer.timeout.connect(spawn_enemy)

	$UI/StartWaveButton.pressed.connect(_on_start_wave_button_pressed)
	$UI/TowerPanel/UpgradeButton.pressed.connect(_on_upgrade_button_pressed)
	$UI/TopBar/RightButtons/SoundButton.pressed.connect(_on_sound_button_pressed)
	$UI/TopBar/RightButtons/SpeedButton.pressed.connect(_on_speed_button_pressed)
	$UI/TopBar/RightButtons/PauseButton.pressed.connect(_on_pause_button_pressed)
	$UI/GameOverPanel/PlayAgainButton.pressed.connect(_on_play_again_pressed)
	$UI/TowerPanel/SellButton.pressed.connect(_on_sell_button_pressed)
	
	$UI/TowerSelectPanel.visible = false

	if town_hall:
		town_hall.setup(base_hp)
		town_hall.destroyed.connect(game_over)
	
	print("Main scene ready")


func setup_tower_buttons():
	$UI/TowerSelectPanel/TowerGrid/BasicTowerBtn.pressed.connect(func(): on_tower_selected(0))
	$UI/TowerSelectPanel/TowerGrid/AOETowerBtn.pressed.connect(func(): on_tower_selected(1))
	$UI/TowerSelectPanel/TowerGrid/SniperTowerBtn.pressed.connect(func(): on_tower_selected(2))
	$UI/TowerSelectPanel/TowerGrid/SlowTowerBtn.pressed.connect(func(): on_tower_selected(3))
	
	update_tower_button_costs()


func update_tower_button_costs():
	$UI/TowerSelectPanel/TowerGrid/BasicTowerBtn/CostLabel.text = str(TOWER_COSTS[0]) + "$"
	$UI/TowerSelectPanel/TowerGrid/AOETowerBtn/CostLabel.text = str(TOWER_COSTS[1]) + "$"
	$UI/TowerSelectPanel/TowerGrid/SniperTowerBtn/CostLabel.text = str(TOWER_COSTS[2]) + "$"
	$UI/TowerSelectPanel/TowerGrid/SlowTowerBtn/CostLabel.text = str(TOWER_COSTS[3]) + "$"
	
	$UI/TowerSelectPanel/TowerGrid/BasicTowerBtn.disabled = money < TOWER_COSTS[0]
	$UI/TowerSelectPanel/TowerGrid/AOETowerBtn.disabled = money < TOWER_COSTS[1]
	$UI/TowerSelectPanel/TowerGrid/SniperTowerBtn.disabled = money < TOWER_COSTS[2]
	$UI/TowerSelectPanel/TowerGrid/SlowTowerBtn.disabled = money < TOWER_COSTS[3]


func _on_start_wave_button_pressed():
	if wave_in_progress or ui_manager.is_game_over_visible():
		return

	wave_in_progress = true
	$SpawnTimer.start()
	show_warning("Wave " + str(wave) + " started")
	update_wave_button_state()


func update_wave_button_state():
	var start_wave_button = $UI/StartWaveButton
	start_wave_button.disabled = wave_in_progress or ui_manager.is_game_over_visible()

	if wave_in_progress:
		start_wave_button.text = "Wave In Progress"
	else:
		start_wave_button.text = "Start Wave " + str(wave)


func on_tower_selected(tower_type: int):
	if pending_build_spot == null:
		return
	
	var cost = TOWER_COSTS[tower_type]
	
	if money < cost:
		show_warning("Cannot afford this tower")
		cancel_build_spot()
		return
	
	var tower = build_manager.build_at(pending_build_spot.global_position, cost, tower_type)

	if tower == null:
		cancel_build_spot()
		return

	money -= cost
	update_ui()
	
	print("Built " + TOWER_NAMES[tower_type] + " tower, remaining money:", money)

	cancel_build_spot()
	select_tower(tower)


func cancel_build_spot():
	pending_build_spot = null
	$UI/TowerSelectPanel.visible = false


func _on_sound_button_pressed():
	sound_enabled = !sound_enabled

	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus_index, not sound_enabled)

	var icon = $UI/TopBar/RightButtons/SoundButton/Icon
	icon.texture = SOUND_ICON_ON if sound_enabled else SOUND_ICON_OFF
	icon.modulate = Color.WHITE


func _on_speed_button_pressed():
	if is_paused:
		return

	if game_speed == 1.0:
		game_speed = 2.0
	else:
		game_speed = 1.0

	Engine.time_scale = game_speed

	var icon = $UI/TopBar/RightButtons/SpeedButton/Icon
	icon.texture = SPEED_ICON_2X if game_speed == 2.0 else SPEED_ICON_1X
	icon.modulate = Color.WHITE


func _on_pause_button_pressed():
	is_paused = !is_paused
	get_tree().paused = is_paused

	var icon = $UI/TopBar/RightButtons/PauseButton/Icon
	icon.texture = PAUSE_ICON_OFF if is_paused else PAUSE_ICON_ON
	icon.modulate = Color.WHITE


func spawn_enemy():
	var enemy_scene = get_enemy_scene_for_wave()

	if enemy_scene == null:
		print("Enemy scene is not assigned")
		return

	if enemies_spawned >= enemies_to_spawn:
		$SpawnTimer.stop()
		return

	enemies_spawned += 1
	enemies_alive += 1

	var enemy = enemy_scene.instantiate()
	$Path2D.add_child(enemy)

	if audio_manager and enemy.has_method("get"):
		audio_manager.play_enemy_spawn(enemy.enemy_name)

	enemy.reached_base.connect(_on_enemy_reached_base)
	enemy.died.connect(_on_enemy_died)


func setup_hp_bar_style():
	if not has_node("HPBar"):
		return

	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3

	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.2, 1.0, 0.25, 1.0)
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3

	$HPBar.add_theme_stylebox_override("background", bg)
	$HPBar.add_theme_stylebox_override("fill", fill)
	$HPBar.show_percentage = false


func get_enemy_scene_for_wave():
	if wave % 5 == 0:
		if enemies_spawned == enemies_to_spawn - 1:
			return boss_enemy_scene

	if wave <= 2:
		return normal_enemy_scene

	if wave <= 4:
		var r = randf()
		if r < 0.7:
			return normal_enemy_scene
		return fast_enemy_scene

	if wave <= 9:
		var r = randf()
		if r < 0.5:
			return normal_enemy_scene
		elif r < 0.8:
			return fast_enemy_scene
		return tank_enemy_scene

	var r = randf()
	if r < 0.4:
		return normal_enemy_scene
	elif r < 0.65:
		return fast_enemy_scene
	elif r < 0.9:
		return tank_enemy_scene

	return boss_enemy_scene


func _on_enemy_died(reward, pos):
	money += reward
	enemies_alive -= 1

	spawn_coin_text(pos, reward)
	audio_manager.play_sfx("EnemyDieSound")

	update_ui()
	update_tower_button_costs()
	check_wave_end()


func spawn_coin_text(world_pos: Vector2, amount: int):
	if floating_text_scene == null:
		print("FloatingText scene is not assigned")
		return

	var text = floating_text_scene.instantiate()
	add_child(text)

	text.global_position = world_pos + Vector2(0, -45)
	text.setup_text("+" + str(amount) + "$", Color.GOLD)

	var target_pos = $UI/TopBar/LeftStats/MoneyPanel/HBoxContainer/MoneyLabel.global_position
	text.fly_to(target_pos)


func _on_enemy_reached_base():
	base_hp -= 1
	enemies_alive -= 1

	if town_hall:
		town_hall.take_damage(1)

	update_ui()
	base_hit_feedback()

	if base_hp <= 0:
		game_over()
		return

	check_wave_end()


func game_over():
	print("GAME OVER")

	wave_in_progress = false
	update_wave_button_state()
	$SpawnTimer.stop()
		
	if bgm_player.playing:
		bgm_player.stop()

	ui_manager.show_game_over(wave)
	audio_manager.play_sfx("GameOverSound")


func _on_play_again_pressed():
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func check_wave_end():
	if enemies_spawned >= enemies_to_spawn and enemies_alive <= 0:
		wave_in_progress = false
		start_next_wave()


func start_next_wave():
	wave += 1
	enemies_spawned = 0
	enemies_to_spawn += 5

	update_ui()
	update_wave_button_state()
	show_warning("Wave " + str(wave) + " ready")
	print("Wave", wave)


func _input(event):
	if ui_manager.is_game_over_visible():
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		
		var mouse_pos = get_global_mouse_position()
		
		if ui_manager.is_click_on_ui(event.position):
			return
		
		var clicked_tower = build_manager.get_tower_at(mouse_pos)
		if clicked_tower != null:
			cancel_build_spot()
			select_tower(clicked_tower)
			return
		
		var clicked_spot = build_manager.get_build_spot_at(mouse_pos)
		
		if pending_build_spot != null:
			if clicked_spot == pending_build_spot:
				return
			cancel_build_spot()
			return
		
		if clicked_spot != null and not clicked_spot.occupied:
			pending_build_spot = clicked_spot
			$UI/TowerSelectPanel.visible = true
			update_tower_button_costs()
			return
		
		deselect_tower()


func show_warning(text: String):
	var label = $UI/WarningLabel

	label.text = text
	label.visible = true
	label.modulate.a = 1.0
	label.scale = Vector2(1.0, 1.0)

	if warning_tween:
		warning_tween.kill()

	warning_tween = create_tween()
	warning_tween.tween_property(label, "scale", Vector2(1.1, 1.1), 0.08)
	warning_tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.08)
	warning_tween.tween_interval(1.0)
	warning_tween.tween_property(label, "modulate:a", 0.0, 0.35)
	warning_tween.tween_callback(func():
		label.visible = false
	)


func _on_sell_button_pressed():
	if selected_tower == null or not is_instance_valid(selected_tower):
		return

	var sell_value = selected_tower.get_sell_value()

	money += sell_value
	update_ui()
	update_tower_button_costs()

	selected_tower.set_selected(false)

	build_manager.clear_tower(selected_tower)

	selected_tower.queue_free()
	selected_tower = null

	ui_manager.hide_tower_panel()

	show_warning("Sold tower +" + str(sell_value))


func select_tower(tower):
	if selected_tower != null and is_instance_valid(selected_tower):
		selected_tower.set_selected(false)

	selected_tower = tower
	selected_tower.set_selected(true)

	ui_manager.show_tower_panel(selected_tower)

	print("Selected tower")


func deselect_tower():
	if selected_tower != null and is_instance_valid(selected_tower):
		selected_tower.set_selected(false)

	selected_tower = null
	ui_manager.hide_tower_panel()


func update_ui():
	ui_manager.update_top_bar(money, base_hp, wave)


func update_tower_panel():
	if selected_tower != null and is_instance_valid(selected_tower):
		ui_manager.show_tower_panel(selected_tower)
	update_ui()
	

func _on_upgrade_button_pressed():
	if selected_tower == null:
		return

	if not selected_tower.can_upgrade():
		show_warning("Tower is already max level")
		update_tower_panel()
		return

	var cost = selected_tower.get_upgrade_cost()

	if money < cost:
		show_warning("Not enough money to upgrade")
		return

	money -= cost
	selected_tower.upgrade()
	update_ui()
	update_tower_button_costs()

	audio_manager.play_sfx("UpgradeSound")

	update_ui()
	update_tower_panel()


func base_hit_feedback():
	audio_manager.play_sfx("BaseHitSound")
	ui_manager.animate_hp_panel_hit()

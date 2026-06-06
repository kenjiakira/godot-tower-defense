extends Node2D

@export var normal_enemy_scene: PackedScene
@export var fast_enemy_scene: PackedScene
@export var tank_enemy_scene: PackedScene
@export var boss_enemy_scene: PackedScene

@export var floating_text_scene: PackedScene
@export var hud_scene: PackedScene

@onready var town_hall = $TownHall
@onready var audio_manager = $Managers/AudioManager
@onready var ui_manager = $Managers/UIManager
@onready var build_manager = $Managers/BuildManager
@onready var wave_manager = $Managers/WaveManager
@onready var effects_manager = $Managers/EffectsManager
@onready var bgm_player = $SFX/BGMSound

var hud: CanvasLayer
var sound_enabled := true
var enemies_to_spawn := 10

const SOUND_ICON_ON = preload("res://assets/ui/right_topbar_icon/volume.png")
const SOUND_ICON_OFF = preload("res://assets/ui/right_topbar_icon/volume_disable.png")
const PAUSE_ICON_ON = preload("res://assets/ui/right_topbar_icon/pause.png")
const PAUSE_ICON_OFF = preload("res://assets/ui/right_topbar_icon/pause_disable.png")
const SPEED_ICON_1X = preload("res://assets/ui/right_topbar_icon/speed_1x.png")
const SPEED_ICON_2X = preload("res://assets/ui/right_topbar_icon/speed_2x.png")


func _ready():
	Engine.time_scale = 1.0
	get_tree().paused = false
	GameState.reset()

	spawn_hud()
	setup_managers()

	if not bgm_player.playing:
		bgm_player.play()

	setup_hp_bar_style()
	update_ui()
	update_wave_button_state()


func spawn_hud():
	if hud_scene != null:
		hud = hud_scene.instantiate()
	else:
		hud = preload("res://scenes/ui/hud.tscn").instantiate()

	add_child(hud)
	connect_hud_signals()


func connect_hud_signals():
	if hud == null:
		push_error("HUD not found")
		return

	hud.start_wave_pressed.connect(_on_start_wave_button_pressed)
	hud.sound_button_pressed.connect(_on_sound_button_pressed)
	hud.pause_button_pressed.connect(_on_pause_button_pressed)
	hud.speed_button_pressed.connect(_on_speed_button_pressed)
	hud.tower_upgrade_pressed.connect(_on_upgrade_button_pressed)
	hud.tower_sell_pressed.connect(_on_sell_button_pressed)
	hud.play_again_pressed.connect(_on_play_again_pressed)
	setup_tower_buttons()


func setup_managers():
	wave_manager.setup(self, $SpawnTimer, $Path2D, audio_manager)
	wave_manager.set_enemy_scenes(normal_enemy_scene, fast_enemy_scene, tank_enemy_scene, boss_enemy_scene)
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.enemy_died.connect(_on_enemy_died)
	wave_manager.enemy_reached_base.connect(_on_enemy_reached_base)
	wave_manager.wave_cleared.connect(_on_wave_cleared)

	build_manager.audio_manager = audio_manager
	build_manager.projectiles_root = $Bullets

	effects_manager.floating_text_scene = floating_text_scene
	effects_manager.effects_root = self

	if town_hall:
		town_hall.setup(GameState.base_hp)
		town_hall.destroyed.connect(game_over)

	print("Main scene ready")


func setup_tower_buttons():
	var panel = hud.tower_select_panel
	if panel == null or not panel.has_node("TowerGrid"):
		return

	var grid = panel.get_node("TowerGrid")
	if grid.has_node("BasicTowerBtn"):
		grid.get_node("BasicTowerBtn").pressed.connect(func(): on_tower_selected(GameConfig.TOWER_BASIC))
	if grid.has_node("AOETowerBtn"):
		grid.get_node("AOETowerBtn").pressed.connect(func(): on_tower_selected(GameConfig.TOWER_AOE))
	if grid.has_node("SniperTowerBtn"):
		grid.get_node("SniperTowerBtn").pressed.connect(func(): on_tower_selected(GameConfig.TOWER_SNIPER))
	if grid.has_node("SlowTowerBtn"):
		grid.get_node("SlowTowerBtn").pressed.connect(func(): on_tower_selected(GameConfig.TOWER_SLOW))

	update_tower_button_costs()


func _on_start_wave_button_pressed():
	if GameState.wave_in_progress or hud.is_game_over_visible():
		return

	wave_manager.start_wave(GameState.wave, enemies_to_spawn)


func _on_wave_started(current_wave: int):
	GameState.wave_in_progress = true
	hud.show_warning("Wave " + str(current_wave) + " started")
	update_wave_button_state()


func update_wave_button_state():
	var disabled = GameState.wave_in_progress or hud.is_game_over_visible()
	var text = "Wave In Progress" if GameState.wave_in_progress else "Start Wave " + str(GameState.wave)
	hud.update_wave_button_state(disabled, text)


func on_tower_selected(tower_type: int):
	if GameState.pending_build_spot == null:
		return

	var cost = GameConfig.get_tower_cost(tower_type)

	if GameState.money < cost:
		hud.show_warning("Cannot afford this tower")
		cancel_build_spot()
		return

	var tower = build_manager.build_at(GameState.pending_build_spot.global_position, cost, tower_type)

	if tower == null:
		cancel_build_spot()
		return

	GameState.money -= cost
	update_ui()
	update_tower_button_costs()

	print("Built " + GameConfig.get_tower_name(tower_type) + " tower, remaining money:", GameState.money)

	cancel_build_spot()
	select_tower(tower)


func cancel_build_spot():
	GameState.pending_build_spot = null
	hud.tower_select_panel.visible = false


func _on_sound_button_pressed():
	sound_enabled = !sound_enabled
	audio_manager.set_sound_enabled(sound_enabled)
	hud.update_sound_icon(sound_enabled)


func _on_speed_button_pressed():
	if GameState.is_paused:
		return

	if GameState.game_speed == 1.0:
		GameState.game_speed = 2.0
	else:
		GameState.game_speed = 1.0

	Engine.time_scale = GameState.game_speed
	hud.update_speed_icon(GameState.game_speed)


func _on_pause_button_pressed():
	GameState.is_paused = !GameState.is_paused
	get_tree().paused = GameState.is_paused
	hud.update_pause_icon(GameState.is_paused)


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


func _on_enemy_died(reward, pos):
	GameState.money += reward
	effects_manager.show_coin_text(pos, reward, hud.money_label.global_position)
	audio_manager.play_sfx("EnemyDieSound")

	update_ui()
	update_tower_button_costs()


func _on_enemy_reached_base():
	GameState.base_hp -= 1

	if town_hall:
		town_hall.take_damage(1)

	update_ui()
	base_hit_feedback()

	if GameState.base_hp <= 0:
		game_over()


func _on_wave_cleared():
	GameState.wave_in_progress = false
	GameState.wave += 1
	enemies_to_spawn += 5
	update_ui()
	update_wave_button_state()
	hud.show_warning("Wave " + str(GameState.wave) + " ready")
	print("Wave", GameState.wave)


func game_over():
	print("GAME OVER")

	GameState.wave_in_progress = false
	update_wave_button_state()
	wave_manager.stop_wave()

	if bgm_player.playing:
		bgm_player.stop()

	hud.show_game_over(GameState.wave)
	audio_manager.play_sfx("GameOverSound")


func _on_play_again_pressed():
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func _input(event):
	if hud.is_game_over_visible():
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		var mouse_pos = get_global_mouse_position()

		if hud.is_click_on_ui(event.position):
			return

		var clicked_tower = build_manager.get_tower_at(mouse_pos)
		if clicked_tower != null:
			cancel_build_spot()
			select_tower(clicked_tower)
			return

		var clicked_spot = build_manager.get_build_spot_at(mouse_pos)

		if GameState.pending_build_spot != null:
			if clicked_spot == GameState.pending_build_spot:
				return
			cancel_build_spot()
			return

		if clicked_spot != null and not clicked_spot.occupied:
			GameState.pending_build_spot = clicked_spot
			hud.tower_select_panel.visible = true
			update_tower_button_costs()
			return

		deselect_tower()


func _on_sell_button_pressed():
	if GameState.selected_tower == null or not is_instance_valid(GameState.selected_tower):
		return

	var sell_value = GameState.selected_tower.get_sell_value()

	GameState.money += sell_value
	update_ui()
	update_tower_button_costs()

	GameState.selected_tower.set_selected(false)
	build_manager.clear_tower(GameState.selected_tower)
	GameState.selected_tower.queue_free()
	GameState.selected_tower = null

	hud.hide_tower_panel()
	hud.show_warning("Sold tower +" + str(sell_value))


func select_tower(tower):
	if GameState.selected_tower != null and is_instance_valid(GameState.selected_tower):
		GameState.selected_tower.set_selected(false)

	GameState.selected_tower = tower
	GameState.selected_tower.set_selected(true)
	hud.show_tower_panel(GameState.selected_tower)
	print("Selected tower")


func deselect_tower():
	if GameState.selected_tower != null and is_instance_valid(GameState.selected_tower):
		GameState.selected_tower.set_selected(false)

	GameState.selected_tower = null
	hud.hide_tower_panel()


func update_ui():
	hud.update_top_bar(GameState.money, GameState.base_hp, GameState.wave)


func update_tower_panel():
	if GameState.selected_tower != null and is_instance_valid(GameState.selected_tower):
		hud.show_tower_panel(GameState.selected_tower)
	update_ui()


func _on_upgrade_button_pressed():
	if GameState.selected_tower == null:
		return

	if not GameState.selected_tower.can_upgrade():
		hud.show_warning("Tower is already max level")
		update_tower_panel()
		return

	var cost = GameState.selected_tower.get_upgrade_cost()

	if GameState.money < cost:
		hud.show_warning("Not enough money to upgrade")
		return

	GameState.money -= cost
	GameState.selected_tower.upgrade()
	update_ui()
	update_tower_button_costs()
	audio_manager.play_sfx("UpgradeSound")
	update_tower_panel()


func base_hit_feedback():
	audio_manager.play_sfx("BaseHitSound")


func update_tower_button_costs():
	var basic_cost = GameConfig.get_tower_cost(GameConfig.TOWER_BASIC)
	var aoe_cost = GameConfig.get_tower_cost(GameConfig.TOWER_AOE)
	var sniper_cost = GameConfig.get_tower_cost(GameConfig.TOWER_SNIPER)
	var slow_cost = GameConfig.get_tower_cost(GameConfig.TOWER_SLOW)

	var panel = hud.tower_select_panel
	if panel == null or not panel.has_node("TowerGrid"):
		return

	var grid = panel.get_node("TowerGrid")

	var btns = [
		["BasicTowerBtn", basic_cost],
		["AOETowerBtn", aoe_cost],
		["SniperTowerBtn", sniper_cost],
		["SlowTowerBtn", slow_cost]
	]

	for entry in btns:
		var btn_name: String = entry[0]
		var cost: int = entry[1]
		if grid.has_node(btn_name):
			var btn = grid.get_node(btn_name)
			if btn.has_node("CostLabel"):
				btn.get_node("CostLabel").text = str(cost) + "$"
			btn.disabled = GameState.money < cost

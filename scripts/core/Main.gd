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
@onready var wave_manager = $Managers/WaveManager
@onready var effects_manager = $Managers/EffectsManager
@onready var bgm_player = $SFX/BGMSound

var warning_tween: Tween
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
	setup_managers()

	if not bgm_player.playing:
		bgm_player.play()

	ui_manager.setup()
	update_ui()
	setup_hp_bar_style()
	setup_tower_buttons()
	update_wave_button_state()

	$UI/StartWaveButton.pressed.connect(_on_start_wave_button_pressed)
	$UI/TowerPanel/UpgradeButton.pressed.connect(_on_upgrade_button_pressed)
	$UI/TopBar/RightButtons/SoundButton.pressed.connect(_on_sound_button_pressed)
	$UI/TopBar/RightButtons/SpeedButton.pressed.connect(_on_speed_button_pressed)
	$UI/TopBar/RightButtons/PauseButton.pressed.connect(_on_pause_button_pressed)
	$UI/GameOverPanel/PlayAgainButton.pressed.connect(_on_play_again_pressed)
	$UI/TowerPanel/SellButton.pressed.connect(_on_sell_button_pressed)

	$UI/TowerSelectPanel.visible = false

	if town_hall:
		town_hall.setup(GameState.base_hp)
		town_hall.destroyed.connect(game_over)

	print("Main scene ready")


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


func setup_tower_buttons():
	$UI/TowerSelectPanel/TowerGrid/BasicTowerBtn.pressed.connect(func(): on_tower_selected(GameConfig.TOWER_BASIC))
	$UI/TowerSelectPanel/TowerGrid/AOETowerBtn.pressed.connect(func(): on_tower_selected(GameConfig.TOWER_AOE))
	$UI/TowerSelectPanel/TowerGrid/SniperTowerBtn.pressed.connect(func(): on_tower_selected(GameConfig.TOWER_SNIPER))
	$UI/TowerSelectPanel/TowerGrid/SlowTowerBtn.pressed.connect(func(): on_tower_selected(GameConfig.TOWER_SLOW))

	update_tower_button_costs()


func update_tower_button_costs():
	var basic_cost = GameConfig.get_tower_cost(GameConfig.TOWER_BASIC)
	var aoe_cost = GameConfig.get_tower_cost(GameConfig.TOWER_AOE)
	var sniper_cost = GameConfig.get_tower_cost(GameConfig.TOWER_SNIPER)
	var slow_cost = GameConfig.get_tower_cost(GameConfig.TOWER_SLOW)

	$UI/TowerSelectPanel/TowerGrid/BasicTowerBtn/CostLabel.text = str(basic_cost) + "$"
	$UI/TowerSelectPanel/TowerGrid/AOETowerBtn/CostLabel.text = str(aoe_cost) + "$"
	$UI/TowerSelectPanel/TowerGrid/SniperTowerBtn/CostLabel.text = str(sniper_cost) + "$"
	$UI/TowerSelectPanel/TowerGrid/SlowTowerBtn/CostLabel.text = str(slow_cost) + "$"

	$UI/TowerSelectPanel/TowerGrid/BasicTowerBtn.disabled = GameState.money < basic_cost
	$UI/TowerSelectPanel/TowerGrid/AOETowerBtn.disabled = GameState.money < aoe_cost
	$UI/TowerSelectPanel/TowerGrid/SniperTowerBtn.disabled = GameState.money < sniper_cost
	$UI/TowerSelectPanel/TowerGrid/SlowTowerBtn.disabled = GameState.money < slow_cost


func _on_start_wave_button_pressed():
	if GameState.wave_in_progress or ui_manager.is_game_over_visible():
		return

	wave_manager.start_wave(GameState.wave, enemies_to_spawn)


func _on_wave_started(current_wave: int):
	GameState.wave_in_progress = true
	show_warning("Wave " + str(current_wave) + " started")
	update_wave_button_state()


func update_wave_button_state():
	var start_wave_button = $UI/StartWaveButton
	start_wave_button.disabled = GameState.wave_in_progress or ui_manager.is_game_over_visible()

	if GameState.wave_in_progress:
		start_wave_button.text = "Wave In Progress"
	else:
		start_wave_button.text = "Start Wave " + str(GameState.wave)


func on_tower_selected(tower_type: int):
	if GameState.pending_build_spot == null:
		return

	var cost = GameConfig.get_tower_cost(tower_type)

	if GameState.money < cost:
		show_warning("Cannot afford this tower")
		cancel_build_spot()
		return

	var tower = build_manager.build_at(GameState.pending_build_spot.global_position, cost, tower_type)

	if tower == null:
		cancel_build_spot()
		return

	GameState.money -= cost
	update_ui()

	print("Built " + GameConfig.get_tower_name(tower_type) + " tower, remaining money:", GameState.money)

	cancel_build_spot()
	select_tower(tower)


func cancel_build_spot():
	GameState.pending_build_spot = null
	$UI/TowerSelectPanel.visible = false


func _on_sound_button_pressed():
	sound_enabled = !sound_enabled
	audio_manager.set_sound_enabled(sound_enabled)

	var icon = $UI/TopBar/RightButtons/SoundButton/Icon
	icon.texture = SOUND_ICON_ON if sound_enabled else SOUND_ICON_OFF
	icon.modulate = Color.WHITE


func _on_speed_button_pressed():
	if GameState.is_paused:
		return

	if GameState.game_speed == 1.0:
		GameState.game_speed = 2.0
	else:
		GameState.game_speed = 1.0

	Engine.time_scale = GameState.game_speed

	var icon = $UI/TopBar/RightButtons/SpeedButton/Icon
	icon.texture = SPEED_ICON_2X if GameState.game_speed == 2.0 else SPEED_ICON_1X
	icon.modulate = Color.WHITE


func _on_pause_button_pressed():
	GameState.is_paused = !GameState.is_paused
	get_tree().paused = GameState.is_paused

	var icon = $UI/TopBar/RightButtons/PauseButton/Icon
	icon.texture = PAUSE_ICON_OFF if GameState.is_paused else PAUSE_ICON_ON
	icon.modulate = Color.WHITE


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
	effects_manager.show_coin_text(pos, reward, $UI/TopBar/LeftStats/MoneyPanel/HBoxContainer/MoneyLabel.global_position)
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
	show_warning("Wave " + str(GameState.wave) + " ready")
	print("Wave", GameState.wave)


func game_over():
	print("GAME OVER")

	GameState.wave_in_progress = false
	update_wave_button_state()
	wave_manager.stop_wave()

	if bgm_player.playing:
		bgm_player.stop()

	ui_manager.show_game_over(GameState.wave)
	audio_manager.play_sfx("GameOverSound")


func _on_play_again_pressed():
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


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

		if GameState.pending_build_spot != null:
			if clicked_spot == GameState.pending_build_spot:
				return
			cancel_build_spot()
			return

		if clicked_spot != null and not clicked_spot.occupied:
			GameState.pending_build_spot = clicked_spot
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

	ui_manager.hide_tower_panel()
	show_warning("Sold tower +" + str(sell_value))


func select_tower(tower):
	if GameState.selected_tower != null and is_instance_valid(GameState.selected_tower):
		GameState.selected_tower.set_selected(false)

	GameState.selected_tower = tower
	GameState.selected_tower.set_selected(true)
	ui_manager.show_tower_panel(GameState.selected_tower)
	print("Selected tower")


func deselect_tower():
	if GameState.selected_tower != null and is_instance_valid(GameState.selected_tower):
		GameState.selected_tower.set_selected(false)

	GameState.selected_tower = null
	ui_manager.hide_tower_panel()


func update_ui():
	ui_manager.update_top_bar(GameState.money, GameState.base_hp, GameState.wave)


func update_tower_panel():
	if GameState.selected_tower != null and is_instance_valid(GameState.selected_tower):
		ui_manager.show_tower_panel(GameState.selected_tower)
	update_ui()


func _on_upgrade_button_pressed():
	if GameState.selected_tower == null:
		return

	if not GameState.selected_tower.can_upgrade():
		show_warning("Tower is already max level")
		update_tower_panel()
		return

	var cost = GameState.selected_tower.get_upgrade_cost()

	if GameState.money < cost:
		show_warning("Not enough money to upgrade")
		return

	GameState.money -= cost
	GameState.selected_tower.upgrade()
	update_ui()
	update_tower_button_costs()
	audio_manager.play_sfx("UpgradeSound")
	update_ui()
	update_tower_panel()


func base_hit_feedback():
	audio_manager.play_sfx("BaseHitSound")
	ui_manager.animate_hp_panel_hit()

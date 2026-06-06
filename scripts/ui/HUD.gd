extends CanvasLayer

signal start_wave_pressed
signal sound_button_pressed
signal pause_button_pressed
signal speed_button_pressed
signal tower_upgrade_pressed
signal tower_sell_pressed
signal play_again_pressed

@onready var top_bar: Control = $TopBar
@onready var start_wave_button: Button = $StartWaveButton
@onready var tower_panel: Panel = $TowerPanel
@onready var tower_select_panel = $TowerSelectPanel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var warning_label: Label = $WarningLabel
@onready var game_over_label: Label = $GameOverPanel/GameOverLabel
@onready var result_label: Label = $GameOverPanel/ResultLabel

@onready var money_label: Label = $TopBar/LeftStats/MoneyPanel/HBoxContainer/MoneyLabel
@onready var hp_label: Label = $TopBar/LeftStats/HPPanel/HBoxContainer/HPLabel
@onready var wave_label: Label = $TopBar/LeftStats/WavePanel/HBoxContainer/WaveLabel
@onready var sound_button: Button = $TopBar/RightButtons/SoundButton
@onready var pause_button: Button = $TopBar/RightButtons/PauseButton
@onready var speed_button: Button = $TopBar/RightButtons/SpeedButton
@onready var coin_icon: TextureRect = $TopBar/LeftStats/MoneyPanel/HBoxContainer/CoinIcon
@onready var hp_icon: TextureRect = $TopBar/LeftStats/HPPanel/HBoxContainer/HPIcon
@onready var wave_icon: TextureRect = $TopBar/LeftStats/WavePanel/HBoxContainer/WaveIcon

@onready var tower_name_label: Label = $TowerPanel/NameLabel
@onready var tower_level_label: Label = $TowerPanel/LevelLabel
@onready var tower_desc_label: Label = $TowerPanel/DescLabel
@onready var town_icon: TextureRect = $TowerPanel/TownIcon
@onready var tower_damage_value: Label = $TowerPanel/StatsBox/DamageRow/DamageLabel/ValueLabel
@onready var tower_range_value: Label = $TowerPanel/StatsBox/RangeRow/RangeLabel/ValueLabel
@onready var tower_firerate_value: Label = $TowerPanel/StatsBox/FireRateRow/FireRateLabel/ValueLabel
@onready var upgrade_button: Button = $TowerPanel/UpgradeButton
@onready var sell_button: Button = $TowerPanel/SellButton

const TOWER_ICONS: Dictionary = {
	0: preload("res://assets/ui/town_panel/towers/town_normal.png"),
	1: preload("res://assets/ui/town_panel/towers/town_aoe.png"),
	2: preload("res://assets/ui/town_panel/towers/town_sniper.png"),
	3: preload("res://assets/ui/town_panel/towers/town_slow.png"),
}

const SOUND_ICON_ON: Texture2D = preload("res://assets/ui/right_topbar_icon/volume.png")
const SOUND_ICON_OFF: Texture2D = preload("res://assets/ui/right_topbar_icon/volume_disable.png")
const SPEED_ICON_1X: Texture2D = preload("res://assets/ui/right_topbar_icon/speed_1x.png")
const SPEED_ICON_2X: Texture2D = preload("res://assets/ui/right_topbar_icon/speed_2x.png")
const PAUSE_ICON_ON: Texture2D = preload("res://assets/ui/right_topbar_icon/pause.png")
const PAUSE_ICON_OFF: Texture2D = preload("res://assets/ui/right_topbar_icon/pause_disable.png")


func _ready():
	start_wave_button.pressed.connect(func(): start_wave_pressed.emit())
	sound_button.pressed.connect(func(): sound_button_pressed.emit())
	pause_button.pressed.connect(func(): pause_button_pressed.emit())
	speed_button.pressed.connect(func(): speed_button_pressed.emit())
	upgrade_button.pressed.connect(func(): tower_upgrade_pressed.emit())
	sell_button.pressed.connect(func(): tower_sell_pressed.emit())
	$GameOverPanel/PlayAgainButton.pressed.connect(func(): play_again_pressed.emit())

	_apply_button_feedback(start_wave_button)
	_apply_button_feedback(sound_button)
	_apply_button_feedback(pause_button)
	_apply_button_feedback(speed_button)
	_apply_button_feedback(upgrade_button)
	_apply_button_feedback(sell_button)
	_apply_button_feedback($GameOverPanel/PlayAgainButton)


func _apply_button_feedback(button: Button):
	button.mouse_entered.connect(func():
		if not button.disabled:
			button.scale = Vector2(1.04, 1.04)
	)
	button.mouse_exited.connect(func():
		button.scale = Vector2.ONE
	)
	button.button_down.connect(func():
		if not button.disabled:
			button.scale = Vector2(0.97, 0.97)
	)
	button.button_up.connect(func():
		if not button.disabled:
			button.scale = Vector2(1.04, 1.04) if button.get_rect().has_point(button.get_local_mouse_position()) else Vector2.ONE
	)


func update_top_bar(money: int, base_hp: int, wave: int):
	money_label.text = str(money)
	hp_label.text = str(base_hp)
	wave_label.text = "Wave: " + str(wave)


func update_wave_button_state(disabled: bool, text: String):
	start_wave_button.disabled = disabled
	start_wave_button.text = text


func show_game_over(wave: int):
	game_over_panel.visible = true
	result_label.text = "You survived Wave " + str(wave)


func hide_game_over():
	game_over_panel.visible = false


func is_game_over_visible() -> bool:
	return game_over_panel.visible


func show_tower_panel(tower):
	tower_panel.visible = true
	var data = tower.get_town_data() if tower != null and tower.has_method("get_town_data") else {}

	tower_name_label.text = str(data.get("type_name", tower.tower_name if tower != null else "Tower"))
	town_icon.texture = _get_town_icon(data.get("tower_type", tower.tower_type if tower != null else 0))
	tower_level_label.text = "Lv." + str(data.get("level", tower.level if tower != null else 1))
	tower_desc_label.text = str(data.get("description", tower.tower_description if tower != null else ""))
	tower_damage_value.text = str(int(data.get("damage", tower.damage if tower != null else 0)))
	tower_range_value.text = str(int(data.get("range", tower.get_range() if tower != null and tower.has_method("get_range") else 0)))
	tower_firerate_value.text = str(snapped(float(data.get("fire_rate", tower.fire_rate if tower != null else 0.0)), 0.01)) + "s"

	var upgrade_cost = tower.get_upgrade_cost()
	var sell_value = tower.get_sell_value()
	upgrade_button.text = "UPGRADE " + str(upgrade_cost)
	sell_button.text = "SELL " + str(sell_value)

	var can_upgrade = GameState.money >= upgrade_cost and tower.level < tower.max_level
	upgrade_button.disabled = not can_upgrade


func hide_tower_panel():
	tower_panel.visible = false


func _get_town_icon(tower_type: int) -> Texture2D:
	return TOWER_ICONS.get(tower_type, TOWER_ICONS.get(0))


func update_sound_icon(enabled: bool):
	$TopBar/RightButtons/SoundButton/Icon.texture = SOUND_ICON_ON if enabled else SOUND_ICON_OFF


func update_pause_icon(is_paused: bool):
	$TopBar/RightButtons/PauseButton/Icon.texture = PAUSE_ICON_OFF if is_paused else PAUSE_ICON_ON


func update_speed_icon(speed: float):
	$TopBar/RightButtons/SpeedButton/Icon.texture = SPEED_ICON_2X if speed > 1.0 else SPEED_ICON_1X


func show_warning(text: String):
	warning_label.text = text
	warning_label.visible = true
	warning_label.modulate.a = 1.0
	warning_label.scale = Vector2(1.0, 1.0)

	var tween = create_tween()
	tween.tween_property(warning_label, "scale", Vector2(1.1, 1.1), 0.08)
	tween.tween_property(warning_label, "scale", Vector2(1.0, 1.0), 0.08)
	tween.tween_interval(1.0)
	tween.tween_property(warning_label, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func():
		warning_label.visible = false
	)


func is_click_on_ui(pos: Vector2) -> bool:
	var top_bar_rect = Rect2(top_bar.global_position, top_bar.size)
	if top_bar_rect.has_point(pos):
		return true
	if tower_panel.visible and Rect2(tower_panel.global_position, tower_panel.size).has_point(pos):
		return true
	if tower_select_panel.visible and Rect2(tower_select_panel.global_position, tower_select_panel.size).has_point(pos):
		return true
	if game_over_panel.visible and Rect2(game_over_panel.global_position, game_over_panel.size).has_point(pos):
		return true
	return false


func set_coin_icon_texture(tex: Texture2D):
	coin_icon.texture = tex


func set_hp_icon_texture(tex: Texture2D):
	hp_icon.texture = tex


func set_wave_icon_texture(tex: Texture2D):
	wave_icon.texture = tex

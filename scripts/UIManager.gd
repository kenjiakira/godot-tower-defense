extends Node

@export var ui_root: CanvasLayer

@onready var top_bar = ui_root.get_node("TopBar")
@onready var right_buttons = ui_root.get_node("TopBar/RightButtons")
@onready var pause_button = ui_root.get_node("TopBar/RightButtons/PauseButton")
@onready var sound_button = ui_root.get_node("TopBar/RightButtons/SoundButton")
@onready var speed_button = ui_root.get_node("TopBar/RightButtons/SpeedButton")

@onready var tower_panel = ui_root.get_node("TowerPanel")

@onready var title_label = ui_root.get_node("TowerPanel/TitleLabel")
@onready var level_label = ui_root.get_node("TowerPanel/LevelLabel")
@onready var name_label = ui_root.get_node("TowerPanel/NameLabel")

@onready var damage_label = ui_root.get_node("TowerPanel/StatsBox/DamageLabel")
@onready var range_label = ui_root.get_node("TowerPanel/StatsBox/RangeLabel")
@onready var fire_rate_label = ui_root.get_node("TowerPanel/StatsBox/FireRateLabel")

@onready var upgrade_button = ui_root.get_node("TowerPanel/UpgradeButton")
@onready var sell_button = ui_root.get_node("TowerPanel/SellButton")

func setup():
	if ui_root == null:
		print("UIManager: ui_root chưa được gán trong Inspector")
		return

	var paths = [
		"TopBar",
		"TopBar/RightButtons",
		"TopBar/RightButtons/SoundButton",
		"TopBar/RightButtons/SpeedButton",
		"TopBar/RightButtons/PauseButton"
	]

	for path in paths:
		if ui_root.has_node(path):
			ui_root.get_node(path).process_mode = Node.PROCESS_MODE_ALWAYS
		else:
			print("UIManager thiếu node:", path)

	ui_root.get_node("TowerPanel").visible = false
	ui_root.get_node("GameOverPanel").visible = false

func update_top_bar(money: int, hp: int, wave: int):
	ui_root.get_node("TopBar/LeftStats/MoneyPanel/HBoxContainer/MoneyLabel").text = str(money)
	ui_root.get_node("TopBar/LeftStats/HPPanel/HBoxContainer/HPLabel").text = str(hp)
	ui_root.get_node("TopBar/LeftStats/WavePanel/HBoxContainer/WaveLabel").text = str(wave)
	animate_money_panel()


func show_tower_panel(tower):
	if tower == null or not is_instance_valid(tower):
		tower_panel.visible = false
		return

	var data = tower.get_town_data()

	tower_panel.visible = true

	title_label.text = "TOWN INFO"
	level_label.text = "Lv." + str(data["level"])
	name_label.text = "Hachiware\nTown"

	damage_label.text = "⚔  Damage        " + str(data["damage"])
	range_label.text = "◎  Range          " + str(data["range"])
	fire_rate_label.text = "◴  Fire Rate      " + str(data["fire_rate"]) + "s"

	if data["can_upgrade"]:
		upgrade_button.text = "UPGRADE  " + str(data["upgrade_cost"])
		upgrade_button.disabled = false
	else:
		upgrade_button.text = "MAX LEVEL"
		upgrade_button.disabled = true

	sell_button.text = "Sell  " + str(data["sell_value"])


func hide_tower_panel():
	ui_root.get_node("TowerPanel").visible = false


func update_tower_panel(tower):
	show_tower_panel(tower)	
	var button = ui_root.get_node("TowerPanel/UpgradeButton")

	if tower.can_upgrade():
		button.text = "Upgrade"
		button.disabled = false
	else:
		button.text = "MAX"
		button.disabled = true


func show_game_over(wave: int):
	ui_root.get_node("GameOverPanel").visible = true
	pause_button.disabled = true

	if ui_root.has_node("GameOverPanel/ResultLabel"):
		ui_root.get_node("GameOverPanel/ResultLabel").text = "You survived Wave " + str(wave)


func is_game_over_visible() -> bool:
	return ui_root.get_node("GameOverPanel").visible


func is_click_on_ui(pos: Vector2) -> bool:
	var ui_nodes = [
		ui_root.get_node("TopBar"),
		ui_root.get_node("TowerPanel")
	]

	for node in ui_nodes:
		if node.visible:
			var rect = Rect2(node.global_position, node.size)
			if rect.has_point(pos):
				return true

	return false


func animate_money_panel():
	var panel = ui_root.get_node("TopBar/LeftStats/MoneyPanel")
	panel.scale = Vector2(1.2, 1.2)

	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.15)


func animate_hp_panel_hit():
	var panel = ui_root.get_node("TopBar/LeftStats/HPPanel")
	var original_pos = panel.position
	var original_modulate = panel.modulate

	panel.modulate = Color(1, 0.25, 0.25)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "position", original_pos + Vector2(8, 0), 0.04)
	tween.tween_property(panel, "modulate", original_modulate, 0.25)

	await tween.finished

	var shake_tween = create_tween()
	shake_tween.tween_property(panel, "position", original_pos + Vector2(-8, 0), 0.04)
	shake_tween.tween_property(panel, "position", original_pos + Vector2(5, 0), 0.04)
	shake_tween.tween_property(panel, "position", original_pos, 0.04)

extends Node2D

@export var normal_enemy_scene: PackedScene
@export var fast_enemy_scene: PackedScene
@export var tank_enemy_scene: PackedScene
@export var boss_enemy_scene: PackedScene
@export var tower_scene: PackedScene
@export var tower_cost := 50
@export var floating_text_scene: PackedScene

var selected_tower = null
var money := 100
var base_hp := 10
var wave := 1

var is_paused := false

var enemies_to_spawn := 10
var enemies_spawned := 0
var enemies_alive := 0

func _ready():
	update_ui()

	$UI.process_mode = Node.PROCESS_MODE_ALWAYS
	$UI/PauseButton.process_mode = Node.PROCESS_MODE_ALWAYS

	$SpawnTimer.timeout.connect(spawn_enemy)
	$SpawnTimer.start()

	$UI/TowerPanel/UpgradeButton.pressed.connect(_on_upgrade_button_pressed)
	$UI/TowerPanel.visible = false

	$UI/GameOverPanel.visible = false
	$UI/PauseButton.pressed.connect(_on_pause_button_pressed)
	$UI/GameOverPanel/PlayAgainButton.pressed.connect(_on_play_again_pressed)

	print("Main scene ready")

func spawn_enemy():
	var enemy_scene = get_enemy_scene_for_wave()
	
	if enemy_scene == null:
		print("Chưa gán enemy scene")
		return
	
	if enemies_spawned >= enemies_to_spawn:
		return
	
	enemies_spawned += 1
	enemies_alive += 1
	
	var enemy = enemy_scene.instantiate()
	$Path2D.add_child(enemy)
	
	enemy.reached_base.connect(_on_enemy_reached_base)
	enemy.died.connect(_on_enemy_died)

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
	play_sfx("EnemyDieSound")
	
	update_ui()
	check_wave_end()

func spawn_coin_text(world_pos: Vector2, amount: int):
	if floating_text_scene == null:
		print("Chưa gán FloatingText scene")
		return
	
	var text = floating_text_scene.instantiate()
	add_child(text)

	text.global_position = world_pos + Vector2(0, -45)
	text.setup_text("+" + str(amount) + "$", Color.GOLD)

	var target_pos = $UI/TopBar/MoneyPanel/HBoxContainer/MoneyLabel.global_position
	text.fly_to(target_pos)

func _on_enemy_reached_base():
	base_hp -= 1
	enemies_alive -= 1
	
	update_ui()
	base_hit_feedback()
	
	if base_hp <= 0:
		game_over()
		return
	
	check_wave_end()

func game_over():
	print("GAME OVER")
	$SpawnTimer.stop()
	$UI/GameOverPanel.visible = true
	$UI/PauseButton.disabled = true
	play_sfx("GameOverSound")
	
	if has_node("UI/GameOverPanel/ResultLabel"):
		$UI/GameOverPanel/ResultLabel.text = "You survived Wave " + str(wave)

func _on_play_again_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func check_wave_end():
	if enemies_spawned >= enemies_to_spawn and enemies_alive <= 0:
		start_next_wave()

func start_next_wave():
	wave += 1
	enemies_spawned = 0
	enemies_to_spawn += 5
	
	update_ui()
	print("Wave", wave)

func _input(event):
	if $UI/GameOverPanel.visible:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:

			if is_click_on_ui(event.position):
				return

			var mouse_pos = get_global_mouse_position()
			
			var clicked_tower = get_tower_body_at(mouse_pos)
			if clicked_tower != null:
				select_tower(clicked_tower)
				return
			
			try_place_tower(mouse_pos)
func is_click_on_ui(pos: Vector2) -> bool:
	var ui_nodes = [
		$UI/TopBar,
		$UI/TowerPanel,
		$UI/PauseButton
	]

	for node in ui_nodes:
		if node.visible:
			var rect = Rect2(node.global_position, node.size)
			if rect.has_point(pos):
				return true

	return false
	
func get_tower_body_at(mouse_pos):
	for tower in $Towers.get_children():
		var distance = tower.global_position.distance_to(mouse_pos)
		
		if distance <= 30:
			return tower
	
	return null
	
func try_place_tower(mouse_pos):
	var clicked_spot = get_build_spot_at(mouse_pos)
	
	if clicked_spot == null:
		deselect_tower()
		print("Không thể đặt tower ở đây")
		return
	
	if clicked_spot.occupied:
		print("Ô này đã có tower")
		return
	
	if money < tower_cost:
		print("Không đủ tiền")
		return
	
	if tower_scene == null:
		print("Chưa gán tower_scene")
		return
	
	var tower = tower_scene.instantiate()
	$Towers.add_child(tower)
	tower.global_position = clicked_spot.global_position
	
	clicked_spot.set_occupied()
	money -= tower_cost
	update_ui()
	
	print("Đã đặt tower, còn tiền:", money)
	select_tower(tower)

func get_build_spot_at(mouse_pos):
	for spot in $BuildSpots.get_children():
		if spot is Area2D:
			var shape = spot.get_node("CollisionShape2D").shape
			var local_pos = spot.to_local(mouse_pos)
			
			if shape is RectangleShape2D:
				var half_size = shape.size / 2
				if abs(local_pos.x) <= half_size.x and abs(local_pos.y) <= half_size.y:
					return spot
	
	return null

func select_tower(tower):
	if selected_tower != null and is_instance_valid(selected_tower):
		selected_tower.set_selected(false)
	
	selected_tower = tower
	selected_tower.set_selected(true)
	
	$UI/TowerPanel.visible = true
	update_tower_panel()
	print("Selected tower")

func deselect_tower():
	if selected_tower != null and is_instance_valid(selected_tower):
		selected_tower.set_selected(false)
	
	selected_tower = null
	$UI/TowerPanel.visible = false

func update_ui():
	$UI/TopBar/MoneyPanel/HBoxContainer/MoneyLabel.text = str(money)
	$UI/TopBar/HPPanel/HBoxContainer/HPLabel.text = str(base_hp)
	$UI/TopBar/WavePanel/WaveLabel.text = "Wave: " + str(wave)
	
	animate_money_panel()

func animate_money_panel():
	var panel = $UI/TopBar/MoneyPanel

	panel.scale = Vector2(1.2, 1.2)

	var tween = create_tween()
	tween.tween_property(
		panel,
		"scale",
		Vector2.ONE,
		0.15
	)

func update_tower_panel():
	if selected_tower == null:
		$UI/TowerPanel.visible = false
		return
	
	$UI/TowerPanel/TowerInfoLabel.text = selected_tower.get_info_text()
	
	if selected_tower.can_upgrade():
		$UI/TowerPanel/UpgradeButton.text = "Upgrade"
		$UI/TowerPanel/UpgradeButton.disabled = false
	else:
		$UI/TowerPanel/UpgradeButton.text = "MAX"
		$UI/TowerPanel/UpgradeButton.disabled = true

func _on_upgrade_button_pressed():
	if selected_tower == null:
		return
	
	if not selected_tower.can_upgrade():
		print("Tower đã max level")
		update_tower_panel()
		return
	
	var cost = selected_tower.get_upgrade_cost()
	
	if money < cost:
		print("Không đủ tiền để upgrade")
		return
	
	money -= cost
	selected_tower.upgrade()
	play_sfx("UpgradeSound")
	update_ui()
	update_tower_panel()

func _on_pause_button_pressed():
	is_paused = !is_paused
	get_tree().paused = is_paused
	
	if is_paused:
		$UI/PauseButton.text = "Resume"
	else:
		$UI/PauseButton.text = "Pause"

func play_sfx(sound_name: String):
	var path = "SFX/" + sound_name
	
	if not has_node(path):
		print("Không tìm thấy sound:", path)
		return
	
	var sound = get_node(path)
	sound.play()

func base_hit_feedback():
	play_sfx("BaseHitSound")
	animate_hp_panel_hit()

func animate_hp_panel_hit():
	var panel = $UI/TopBar/HPPanel
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

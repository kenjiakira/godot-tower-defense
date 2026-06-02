extends Node2D

@export var normal_enemy_scene: PackedScene
@export var fast_enemy_scene: PackedScene
@export var tank_enemy_scene: PackedScene
@export var boss_enemy_scene: PackedScene
@export var tower_scene: PackedScene
@export var tower_cost := 50

var selected_tower = null
var money := 100
var base_hp := 10
var wave := 1

var enemies_to_spawn := 10
var enemies_spawned := 0
var enemies_alive := 0

func _ready():
	update_ui()
	$SpawnTimer.timeout.connect(spawn_enemy)
	$SpawnTimer.start()
	$UI/TowerPanel/UpgradeButton.pressed.connect(_on_upgrade_button_pressed)
	$UI/TowerPanel.visible = false
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
		else:
			return fast_enemy_scene
	
	if wave <= 9:
		var r = randf()
		if r < 0.5:
			return normal_enemy_scene
		elif r < 0.8:
			return fast_enemy_scene
		else:
			return tank_enemy_scene
	
	var r = randf()
	if r < 0.4:
		return normal_enemy_scene
	elif r < 0.65:
		return fast_enemy_scene
	elif r < 0.9:
		return tank_enemy_scene
	else:
		return boss_enemy_scene

func _on_enemy_died(reward):
	money += reward
	enemies_alive -= 1
	update_ui()
	check_wave_end()

func _on_enemy_reached_base():
	base_hp -= 1
	enemies_alive -= 1
	update_ui()
	
	if base_hp <= 0:
		print("GAME OVER")
		$SpawnTimer.stop()
		return
	
	check_wave_end()

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
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			
			var clicked_tower = get_tower_at(mouse_pos)
			if clicked_tower != null:
				select_tower(clicked_tower)
				return
			
			try_place_tower(mouse_pos)
			
func get_tower_at(mouse_pos):
	for tower in $Towers.get_children():
		if tower is Area2D:
			var shape = tower.get_node("CollisionShape2D").shape
			var local_pos = tower.to_local(mouse_pos)
			
			if shape is CircleShape2D:
				if local_pos.length() <= 25:
					return tower
	
	return null

func try_place_tower(mouse_pos):
	var clicked_spot = get_build_spot_at(mouse_pos)
	
	if clicked_spot == null:
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
	selected_tower = tower
	$UI/TowerPanel.visible = true
	update_tower_panel()
	print("Selected tower")
	
func update_ui():
	$UI/MoneyLabel.text = "Money: " + str(money)
	$UI/HPLabel.text = "HP: " + str(base_hp)
	$UI/WaveLabel.text = "Wave: " + str(wave)

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
	update_ui()
	update_tower_panel()

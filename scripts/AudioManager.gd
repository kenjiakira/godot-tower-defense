extends Node

@export var sfx_root: Node

func play_sfx(sound_name: String):
	if sfx_root == null:
		print("Chưa gán SFX root")
		return
	
	if not sfx_root.has_node(sound_name):
		print("Không tìm thấy sound:", sound_name)
		return
	
	var sound = sfx_root.get_node(sound_name)
	sound.play()


func play_enemy_spawn(enemy_name: String):
	match enemy_name:
		"Normal":
			play_sfx("EmemyNomalSound")
		"Fast":
			play_sfx("EmemyFastSound")
		"Tank":
			play_sfx("EmemyTankSound")
		"Boss":
			play_sfx("EmemyFastSound")
		_:
			play_sfx("EmemyNomalSound")

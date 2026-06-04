extends Node2D

@export var shard_count := 8
@export var shard_size := Vector2(6, 6)
@export var shard_distance_min := 25.0
@export var shard_distance_max := 55.0
@export var lifetime := 0.35
@export var shard_color := Color.WHITE

func _ready():
	spawn_shards()
	play_center_pop()

func spawn_shards():
	for i in shard_count:
		var shard := ColorRect.new()
		shard.color = shard_color
		shard.size = shard_size
		shard.position = -shard_size / 2.0
		shard.rotation = randf() * TAU

		add_child(shard)

		var dir := Vector2.RIGHT.rotated(randf() * TAU)
		var distance := randf_range(shard_distance_min, shard_distance_max)
		var target_pos := dir * distance

		var tween := create_tween()
		tween.set_parallel(true)

		tween.tween_property(
			shard,
			"position",
			target_pos,
			lifetime
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		tween.tween_property(
			shard,
			"modulate:a",
			0.0,
			lifetime
		)

		tween.tween_property(
			shard,
			"rotation",
			shard.rotation + randf_range(-4.0, 4.0),
			lifetime
		)

func play_center_pop():
	if has_node("Body"):
		$Body.color = shard_color
		$Body.modulate.a = 1.0
		$Body.scale = Vector2.ONE

		var tween := create_tween()
		tween.set_parallel(true)

		tween.tween_property($Body, "scale", Vector2(2.0, 2.0), 0.18)
		tween.tween_property($Body, "modulate:a", 0.0, 0.18)

	await get_tree().create_timer(lifetime).timeout
	queue_free()

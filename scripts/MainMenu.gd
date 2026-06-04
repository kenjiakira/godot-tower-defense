extends Control

@onready var how_to_play_panel = $HowToPlayPanel

func _ready():
	$CenterBox/PlayButton.pressed.connect(_on_play_pressed)
	$CenterBox/HowToPlayButton.pressed.connect(_on_how_to_play_pressed)
	$CenterBox/QuitButton.pressed.connect(_on_quit_pressed)
	$HowToPlayPanel/CloseButton.pressed.connect(_on_close_how_to_play)

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_how_to_play_pressed():
	how_to_play_panel.visible = true

func _on_close_how_to_play():
	how_to_play_panel.visible = false

func _on_quit_pressed():
	get_tree().quit()

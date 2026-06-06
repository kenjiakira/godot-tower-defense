extends Control

signal settings_button_pressed

@onready var settings_panel = $SettingsPanel
@onready var menu_buttons_container = $CenterBox/MenuPanel/VBoxContainer

var menu_buttons: Array[Button] = []
var selected_index: int = 0

func _ready():
	_setup_menu_buttons()
	_connect_signals()
	_load_settings()

func _setup_menu_buttons():
	if menu_buttons_container == null:
		push_warning("MenuButtonsContainer not found!")
		return
	for child in menu_buttons_container.get_children():
		if child is Button:
			menu_buttons.append(child)

func _connect_signals():
	if menu_buttons.is_empty():
		push_warning("No menu buttons found!")
		return
	menu_buttons[0].pressed.connect(_on_play_pressed)
	menu_buttons[1].pressed.connect(_on_how_to_play_pressed)
	menu_buttons[2].pressed.connect(_on_settings_pressed)
	menu_buttons[3].pressed.connect(_on_quit_pressed)
	
	$HowToPlayPanel/CloseButton.pressed.connect(_on_close_how_to_play)
	$SettingsPanel/CloseButton.pressed.connect(_on_close_settings)
	
	$SettingsPanel/SoundRow/SoundSlider.value_changed.connect(_on_sound_volume_changed)
	$SettingsPanel/MusicRow/MusicSlider.value_changed.connect(_on_music_volume_changed)
	$SettingsPanel/FullscreenCheckBox.toggled.connect(_on_fullscreen_toggled)

func _input(event: InputEvent):
	if settings_panel.visible or $HowToPlayPanel.visible:
		return
	
	if event.is_action_pressed("ui_up"):
		_navigate_menu(-1)
	elif event.is_action_pressed("ui_down"):
		_navigate_menu(1)
	elif event.is_action_pressed("ui_accept"):
		_select_current()

func _navigate_menu(direction: int):
	menu_buttons[selected_index].release_focus()
	selected_index = wrapi(selected_index + direction, 0, menu_buttons.size())
	menu_buttons[selected_index].grab_focus()

func _select_current():
	menu_buttons[selected_index].pressed.emit()

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_how_to_play_pressed():
	$HowToPlayPanel.visible = true

func _on_settings_pressed():
	settings_panel.visible = true
	settings_panel.grab_focus()

func _on_quit_pressed():
	get_tree().quit()

func _on_close_how_to_play():
	$HowToPlayPanel.visible = false

func _on_close_settings():
	settings_panel.visible = false
	_save_settings()

func _on_sound_volume_changed(value: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	_update_volume_icon($SettingsPanel/SoundRow/SoundIcon, value)

func _on_music_volume_changed(value: float):
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(value))

func _on_fullscreen_toggled(toggled: bool):
	if toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _update_volume_icon(icon: TextureRect, volume: float):
	if volume <= 0:
		icon.texture = preload("res://assets/ui/right_topbar_icon/volume_disable.png")
	else:
		icon.texture = preload("res://assets/ui/right_topbar_icon/volume.png")

func _load_settings():
	var sound_volume = ProjectSettings.get_setting("game/sound_volume", 1.0)
	var music_volume = ProjectSettings.get_setting("game/music_volume", 1.0)
	var is_fullscreen = ProjectSettings.get_setting("game/fullscreen", false)
	
	$SettingsPanel/SoundRow/SoundSlider.value = sound_volume
	$SettingsPanel/MusicRow/MusicSlider.value = music_volume
	$SettingsPanel/FullscreenCheckBox.button_pressed = is_fullscreen
	
	_on_sound_volume_changed(sound_volume)
	_on_fullscreen_toggled(is_fullscreen)

func _save_settings():
	ProjectSettings.set_setting("game/sound_volume", $SettingsPanel/SoundRow/SoundSlider.value)
	ProjectSettings.set_setting("game/music_volume", $SettingsPanel/MusicRow/MusicSlider.value)
	ProjectSettings.set_setting("game/fullscreen", $SettingsPanel/FullscreenCheckBox.button_pressed)
	ProjectSettings.save()

extends Control

func _ready():
	hide()

func resume():
	hide()
	get_tree().paused = false

func pause():
	show()
	get_tree().paused = true

func testPause():
	if !get_tree().paused and 0:
		pause()

func _on_restart_pressed():
	resume()
	get_tree().reload_current_scene()

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://TitleScreen/TitleScreen.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _process(delta):
	testPause()

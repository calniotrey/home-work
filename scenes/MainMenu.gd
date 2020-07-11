extends Control

var next_scene = preload("res://scenes/Main.tscn")

func _on_StartGame_pressed():
	var game_data = get_node("/root/GameData")
	game_data.difficulty = $Panel/Difficulty.selected
	get_tree().change_scene_to(next_scene)

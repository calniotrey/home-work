extends Control

onready var next_scene = preload("res://scenes/MainMenu.tscn")

func _on_continue():
	get_tree().change_scene_to(next_scene)

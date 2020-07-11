extends Control

var next_scene = preload("res://scenes/Main.tscn")


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_StartGame_pressed():
	var game_data = get_node("/root/GameData")
	if game_data.difficulty > 0:
		get_tree().change_scene_to(next_scene)

func _on_Difficulty_item_selected(index):
	var game_data = get_node("/root/GameData")
	var diffic = $Panel/Difficulty.selected
	game_data.difficulty = diffic

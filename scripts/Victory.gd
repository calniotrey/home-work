extends Control

onready var next_scene = preload("res://scenes/MainMenu.tscn")


func _ready():
	$MoneyParticle.emission_rect_extents.x = rect_size.x


func _on_continue():
	get_tree().change_scene_to(next_scene)


func _on_resized():
	$MoneyParticle.emission_rect_extents.x = rect_size.x

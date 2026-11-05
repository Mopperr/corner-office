extends Node3D


func _ready() -> void:
	var room = preload("res://scripts/diorama.gd").new()
	room.backdrop = true
	add_child(room)

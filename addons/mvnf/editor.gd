@tool
extends Control

@export var character_tree: Tree
var items: Array[TreeItem]
func _ready() -> void:
	items.append(character_tree.create_item())
	items[0].set_text(0, "Godot")
	character_tree.create_item(items[0])

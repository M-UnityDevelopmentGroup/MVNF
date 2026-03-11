@tool
extends EditorPlugin

var DOCK_CONTENT_SCENE = preload("res://addons/mvnf/editor.tscn")
var story_editor: EditorDock

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass



func _enter_tree() -> void:
	print("a")
	story_editor = EditorDock.new()
	story_editor.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	story_editor.add_child(DOCK_CONTENT_SCENE.instantiate())
	story_editor.title = "Story Editor"
	add_dock(story_editor)


func _exit_tree() -> void:
	story_editor.close()

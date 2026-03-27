@tool
extends EditorPlugin

var DOCK_CONTENT_SCENE = preload("res://addons/mvnf/editor.tscn")
var story_editor: EditorDock
var editor_title := "Story Editor"

#func _enable_plugin() -> void:

func _disable_plugin() -> void:
	remove_dock(story_editor)
	story_editor.queue_free()
	
func _enter_tree() -> void:
	story_editor = EditorDock.new()
	story_editor.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	story_editor.add_child(DOCK_CONTENT_SCENE.instantiate())
	story_editor.title = editor_title
	add_dock(story_editor)

#func _exit_tree() -> void:

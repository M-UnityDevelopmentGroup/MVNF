@tool
extends Control
class_name StoryEditor
@export var character_tree: Tree
@export var background_tree: Tree
@export var graph: GraphEdit
@export var node_template: PackedScene
@export var story_actions_popup: PopupMenu
@onready var file_dialog := FileDialog.new()
var current_story: Dictionary
var character_items: Dictionary[String,Array]
var background_items: Dictionary[String,Array]
var background_enum: Dictionary[String,int]
var character_enum: Dictionary[String,int]
var temp_node: StoryNode
var nodes: Array[StoryNode]
var temp_item: TreeItem
var temp_item_parent: TreeItem
var temp_array: Array[TreeItem]
var file: FileAccess
var story_path: String
var is_saving: bool
var story_template: Dictionary = {
	"characters": {
	},
	"backgrounds": {
	},
	"sounds": {
	},
	"phrases": [
	]
}
var template: Dictionary = {
	"type": "",
	"name": "",
	"sprite": "",
	"background": "",
	"background_type": "",
	"text": "",
	"choices": {
	},
	"next": 0,
	"editor_position": {
		"x": 0,
		"y": 0
	}
}
var background: Dictionary = {
	"sprites": {
	},
	"colors": {
	},
	"settings": {
		"expand_mode": 0,
		"stretch_mode": 0
	}
}
var characters: Dictionary = {
	"sprites": {
	},
	"colors": {
	},
	"sounds": {
	},
}

enum story_actions {
	NEW_STORY,
	OPEN_STORY,
	SAVE_STORY,
	SAVE_STORY_AS
}
enum create_actions {
	NODE,
	CHARACTERS,
	BACKGROUNDS,
	SOUNDS
}
func _ready() -> void:
	if not graph.connection_request.is_connected(connect_nodes):
		graph.connection_request.connect(connect_nodes)
	if not graph.disconnection_request.is_connected(disconnect_nodes):
		graph.disconnection_request.connect(disconnect_nodes)
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.display_mode = FileDialog.DISPLAY_LIST
	file_dialog.add_filter("*.json", "JSON")
	file_dialog.file_selected.connect(_process_file)
	add_child(file_dialog)
	
func _list_resourses(resourses: Dictionary, tree: Tree, items: Dictionary[String,Array], enums: Dictionary[String, int]):
	tree.clear()
	temp_item_parent = tree.create_item()
	for i in resourses:
		enums.get_or_add(i, len(enums))
		_list_item(i, resourses, tree, items.get_or_add(i, items.get_or_add(i, temp_array)))
		temp_item_parent = tree.get_root()

func _list_item(item: Variant, resourses: Dictionary, tree: Tree, items: Array[TreeItem], parent: TreeItem = null) -> void:
		temp_item = tree.create_item(temp_item_parent if parent == null else parent)
		temp_item.set_text(0, item)
		temp_item.add_button(1, get_theme_icon("Folder", "EditorIcons"))
		items.append(temp_item)
		if parent == null:
			temp_item_parent = temp_item
		if typeof(resourses.get(item)) == TYPE_DICTIONARY or typeof(resourses.get(item)) == TYPE_ARRAY:
			for i in resourses.get(item):
				_list_item(i, resourses, tree, items, temp_item_parent)

func _manage_stories(id: int) -> void:
	match id as story_actions:
		story_actions.NEW_STORY:
			file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			file_dialog.popup_file_dialog()
		story_actions.OPEN_STORY:
			file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			file_dialog.popup_file_dialog()
		story_actions.SAVE_STORY:
			file = FileAccess.open(story_path, FileAccess.WRITE)
			file.store_string(JSON.stringify(current_story,"\t"))
		story_actions.SAVE_STORY_AS:
			is_saving = true
			file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			file_dialog.popup_file_dialog()

func _manage_nodes(id: int) ->  void:
	match id as create_actions:
		create_actions.NODE:
			temp_node = node_template.instantiate()
			graph.add_child(temp_node)
			temp_node.set_node_properties()

func _process_file(path: String) -> void:
	if not path.get_extension() == "json":
		return
	if not FileAccess.file_exists(path):
		var temp = FileAccess.open(path, FileAccess.WRITE)
		temp.close()
	file = FileAccess.open(path, FileAccess.READ_WRITE)
	if JSON.parse_string(file.get_as_text()) == null and not is_saving:
		file.store_string(JSON.stringify(story_template,"\t"))
		story_actions_popup.set_item_disabled(3, true)
		story_actions_popup.set_item_disabled(4, true)
	elif is_saving:
		file.store_string(JSON.stringify(current_story,"\t"))
		is_saving = false
	story_path = path
	current_story = JSON.parse_string(file.get_as_text())
	story_actions_popup.set_item_disabled(3, false)
	story_actions_popup.set_item_disabled(4, false)
	_open_story(current_story)
	file.close()

func _open_story(story: Dictionary) -> void:
	if (story.has("phrases")):
		for i in graph.find_children("*", "GraphNode"):
			i.queue_free()
		for i in story.phrases:
			temp_node = node_template.instantiate()
			graph.add_child(temp_node)
			temp_node.set_node_properties(i.type, i.text)
	if story.has("backgrounds"):
		_list_resourses(story.backgrounds, background_tree, background_items, background_enum)
	if story.has("characters"):
		_list_resourses(story.characters, character_tree, character_items, character_enum)



func connect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	graph.connect_node(from_node, from_port, to_node, to_port)

func disconnect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	graph.disconnect_node(from_node, from_port, to_node, to_port)

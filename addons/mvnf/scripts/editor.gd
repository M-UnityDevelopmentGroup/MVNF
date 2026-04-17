@tool
extends Control
class_name StoryEditor
@export var character_tree: Tree
@export var background_tree: Tree
@export var graph: GraphEdit
@export var story_path_label: RichTextLabel
@export var node_template: PackedScene
@export var story_actions_popup: PopupMenu
@onready var file_dialog := FileDialog.new()
var current_story: Dictionary
var character_items: Dictionary[String,Array]
var background_items: Dictionary[String,Array]
var background_enum: Dictionary[String,int]
var background_type_enum: Dictionary[String,Dictionary]
var character_enum: Dictionary[String,int]
var sprite_enum: Dictionary[String, Dictionary]
var sound_enum: Dictionary[String, Dictionary]
var temp_node: StoryNode
var temp_node_data: Dictionary
var nodes: Array[StoryNode]
var temp_item: TreeItem
var temp_item_parent: TreeItem
var temp_temp_item_parent: TreeItem
var temp_array: Array[TreeItem]
var temp_enum: Dictionary[String, int]
var tempi: int
var file: FileAccess
var story_path: String
var current_story_action: story_actions
var story_template: Dictionary = {
	"characters": {
	},
	"backgrounds": {
	},
	"phrases": [
	]
}
var template: Dictionary = {
	"type": "text",
	"name": "",
	"sprite": "",
	"background": "",
	"background_type": "",
	"text": "",
	"choices": {
	},
	"next": 0,
	"editor_transform": {
		"position_x": 0,
		"position_y": 0,
		"size_x": 300,
		"size_y": 500
	}
}
var background: Dictionary = {
	"sprites": {
	},
	"colors": {
	},
	"sounds": {
	},
	"settings": {
		"expand_mode": 0,
		"stretch_mode": 0
	}
}
var character: Dictionary = {
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
	CHARACTER,
	BACKGROUND
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
	tree.set_column_custom_minimum_width(0, 200)
	tree.set_column_expand(0,false)
	temp_item_parent = tree.create_item()
	for i in resourses:
		enums.get_or_add(i, len(enums))
		_list_item(i, resourses, tree, items.get_or_add(i, items.get_or_add(i, temp_array)))
		temp_item_parent = tree.get_root()
		
func _list_resourses_to_enum(resourses: Dictionary, enums: Dictionary[String, int]):
	for i in resourses:
		enums.get_or_add(i, len(enums))
		
func _list_resourses_to_enum_dict(resourses: Dictionary, enums: Dictionary[String, Dictionary], key: String):
	for i in resourses:
		temp_enum.get_or_add(i, len(temp_enum))
	enums.get_or_add(key,temp_enum.duplicate(true))


func _list_item(item: Variant, resourses: Dictionary, tree: Tree, items: Array[TreeItem], parent: TreeItem = null) -> void:
	temp_item = tree.create_item(temp_item_parent if parent == null else parent)
	temp_item.set_text(0, item)
	items.append(temp_item)
	if parent == null:
		temp_item_parent = temp_item
	if typeof(resourses.get(item)) == TYPE_DICTIONARY:
		temp_item.add_button(1, get_theme_icon("Add", "EditorIcons"))
		temp_temp_item_parent = temp_item
		for i in resourses.get(item):
			_list_item(i, resourses.get(item), tree, items, temp_temp_item_parent)
	elif not resourses.get(item) == null:
		temp_item.set_editable(0, true)
		temp_item.set_text(1, str(resourses.get(item)))
		temp_item.set_editable(1, true)

func _manage_stories(id: int) -> void:
	current_story_action = id as story_actions
	match id as story_actions:
		story_actions.NEW_STORY:
			file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			file_dialog.popup_file_dialog()
		story_actions.OPEN_STORY:
			file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			file_dialog.popup_file_dialog()
		story_actions.SAVE_STORY:
			await _update_story()
			file = FileAccess.open(story_path, FileAccess.WRITE)
			file.store_string(JSON.stringify(current_story.duplicate(true),"\t"))
		story_actions.SAVE_STORY_AS:
			await _update_story()
			file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			file_dialog.popup_file_dialog()

func _manage_nodes(id: int) ->  void:
	match id as create_actions:
		create_actions.NODE:
			temp_node = node_template.instantiate()
			graph.add_child(temp_node)
			temp_node_data.assign(template)
			current_story.phrases.append(temp_node_data)
			nodes.append(temp_node)
			temp_node.set_node_properties(temp_node_data, current_story.phrases.size() - 1, graph, self)
		

func _process_file(path: String) -> void:
	if not path.get_extension() == "json":
		return
	match current_story_action:
		story_actions.NEW_STORY:
			if not FileAccess.file_exists(path):
				file = FileAccess.open(path, FileAccess.WRITE)
				file.store_string(JSON.stringify(story_template,"\t"))
				current_story = story_template.duplicate(true)
				story_path = path
				story_path_label.text = story_path
				file.close()
				_open_story(current_story)
				story_actions_popup.set_item_disabled(3, false)
				story_actions_popup.set_item_disabled(4, false)
				return
		story_actions.OPEN_STORY:
			file = FileAccess.open(path, FileAccess.READ_WRITE)
			if JSON.parse_string(file.get_as_text()) == null:
				file.store_string(JSON.stringify(story_template,"\t"))
			current_story = JSON.parse_string(file.get_as_text())
			story_path = path
			story_path_label.text = story_path
			file.close()
			_open_story(current_story)
			story_actions_popup.set_item_disabled(3, false)
			story_actions_popup.set_item_disabled(4, false)
			return
		story_actions.SAVE_STORY_AS:
			file = FileAccess.open(path, FileAccess.WRITE)
			file.store_string(JSON.stringify(current_story.duplicate(true),"\t"))
			file.close()
			story_path = path
			story_path_label.text = story_path
			return

func _open_story(story: Dictionary) -> void:
	current_story = story.duplicate(true)
	graph.clear_connections()
	sprite_enum.clear()
	background_enum.clear()
	sound_enum.clear()
	character_enum.clear()
	background_enum.clear()
	tempi = 0
	for i in graph.find_children("*", "StoryNode"):
		i.queue_free()
	for i in nodes:
		i.queue_free()
	nodes.clear()
	if current_story.has("backgrounds"):
		#_list_resourses(current_story.backgrounds, background_tree, background_items, background_enum)
		_list_resourses_to_enum(current_story.backgrounds, background_enum)
		for i in current_story.backgrounds:
			if current_story.backgrounds.get(i).has("sprites"):
				_list_resourses_to_enum_dict(current_story.backgrounds.get(i).sprites, background_type_enum, i)
	if current_story.has("characters"):
		#_list_resourses(current_story.characters, character_tree, character_items, character_enum)
		_list_resourses_to_enum(current_story.characters, character_enum)
		for i in current_story.characters:
			if current_story.characters.get(i).has("sprites"):
				_list_resourses_to_enum_dict(current_story.characters.get(i).sprites, sprite_enum, i)
		print(sprite_enum)
	if (current_story.has("phrases")):
		for i in current_story.phrases:
			temp_node = node_template.instantiate()
			graph.add_child(temp_node)
			nodes.append(temp_node)
			temp_node.set_node_properties(i, tempi, graph, self)
			tempi+=1
		for i in nodes:
			i.set_node_connections(graph)

func _update_story() -> bool:
	current_story.phrases.clear()
	for i in nodes:
		current_story.phrases.append(i.node_data.duplicate(true))
	return true

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_S and event.ctrl_pressed and not story_path == null and not current_story.is_empty():
			_manage_stories(2)
			
func connect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	graph.connect_node(from_node, from_port, to_node, to_port)

func disconnect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	graph.disconnect_node(from_node, from_port, to_node, to_port)

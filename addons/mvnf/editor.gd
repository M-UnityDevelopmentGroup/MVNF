@tool
extends Control

@export var character_tree: Tree
@export var graph: GraphEdit
@export var node_template: PackedScene
@onready var file_dialog := FileDialog.new()
var stories: Array[Dictionary]
var items: Array[TreeItem]
var temp_node: StoryNode
var nodes: Array[StoryNode]
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
	items.append(character_tree.create_item())
	items[0].set_text(0, "Godot")
	character_tree.create_item(items[0])
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.display_mode = FileDialog.DISPLAY_LIST
	file_dialog.add_filter("*.json", "JSON")
	file_dialog.file_selected.connect(_process_file)
	add_child(file_dialog)
	
func _manage_stories(id: int) -> void:
	match id as story_actions:
		story_actions.NEW_STORY:
			file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
			file_dialog.popup_file_dialog()
		story_actions.OPEN_STORY:
			file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			file_dialog.popup_file_dialog()

func _manage_nodes(id: int) ->  void:
	match id as create_actions:
		create_actions.NODE:
			graph.add_child(node_template.instantiate())

func _process_file(path: String) -> void:
	if FileAccess.file_exists(path) and path.get_extension() == "json":
		_open_story(JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text()))

func _open_story(story: Dictionary) -> void:
	if (story.has("phrases")):
		for i in graph.find_children("*", "GraphNode"):
			i.queue_free()
		for i in story.phrases:
			temp_node = node_template.instantiate()
			graph.add_child(temp_node)
			temp_node.set_node_properties(i.type, i.text)
		

func connect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	graph.connect_node(from_node, from_port, to_node, to_port)

func disconnect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	graph.disconnect_node(from_node, from_port, to_node, to_port)

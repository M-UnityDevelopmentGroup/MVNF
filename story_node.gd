@tool
class_name StoryNode
extends GraphNode
@export var type_button: OptionButton
@export var node_text_edit: TextEdit
@export var choice_button: Button
@export var choice_label: Label
@export var text_label: Label
@export var text_edit_label: Label 
@export var choice_template: PackedScene
@export var choice_slot_offset: int
@export var node_popup: PopupMenu
var node_name: String
var node_type: node_types
var node_text: String
var node_choices: Dictionary[String, int]

var choice_templates: Array[Choice]
var temp_text_edit_size: float
var temp_choice: Choice
var temp_choice_size_y: float = 32
enum node_types {
	text,
	choice
}
func _ready() -> void:
	type_button.item_selected.connect(_change_type)
	if not choice_button.pressed.is_connected(_create_choice):
		choice_button.pressed.connect(_create_choice)
	_change_type(0)

func set_node_properties(type: String = "text", text: String = "", choices: Dictionary[String, int] = {}) -> void:
	match type:
		"text":
			_change_type(0)
		"choice":
			_change_type(1)
	node_choices = choices
	for i in node_choices:
		_create_choice()
	node_text_edit.text = text
	
func _change_type(index: int) -> void:
	node_type = index as node_types
	
	match node_type:
		node_types.text:
			text_label.show()
			text_edit_label.show()
			size.y += text_edit_label.size.y
			choice_label.hide()
			for i in choice_templates:
				i.hide()
				size.y -= type_button.size.y
		node_types.choice:
			text_label.hide()
			temp_text_edit_size = text_edit_label.size.y
			text_edit_label.hide()
			size.y -= temp_text_edit_size
			choice_label.show()
			for i in choice_templates:
				i.show()
				size.y += type_button.size.y
	print(node_type)
	
func _create_choice(text: String = "Choice", path: int = -1) -> void:
	if node_choices.has(text):
		text += str(node_choices.size())
	node_choices.set(text,path)
	temp_choice = choice_template.instantiate()
	temp_choice.choice_edit.text = text
	temp_choice.remove_button.pressed.connect(_remove_choice.bind(temp_choice))
	choice_templates.append(temp_choice)
	size.y += temp_choice_size_y
	print(text)
	add_child(temp_choice)
	set_slot_enabled_right(node_choices.size()+choice_slot_offset, true)
	#set_slot_metadata_right(choices.size()+choice_slot_offset, choices.size()+choice_slot_offset)

func _remove_choice(choice: Choice) -> void:
	size.y -= temp_choice_size_y
	node_choices.erase(choice.choice_edit.text)
	choice.queue_free()
	choice_templates.erase(choice)
	


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			node_popup.position = get_global_mouse_position()
			node_popup.popup()
			

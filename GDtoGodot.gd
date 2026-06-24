extends Node

var trigger_once_pool = {
	0 : true
}

func _ready() -> void:
	print("The GDevelop to Godot framework is now ready.")

func key_name_to_keycode(key_name : String) -> Key:
	key_name = key_name.strip_edges().replace("\"", "")
	match key_name:
		"Space": return KEY_SPACE
		"Escape": return KEY_ESCAPE
		"Delete": return KEY_DELETE
		"F4": return KEY_F4
		"LShift": return KEY_SHIFT
		"Left": return KEY_LEFT
		"Right": return KEY_RIGHT
		"Up": return KEY_UP
		"Down": return KEY_DOWN
		"a": return KEY_A
		"d": return KEY_D
		# ... add more letters/keys as you encounter them
		_:
			push_warning("Unmapped key: " + key_name)
			return KEY_NONE

func is_key_pressed(keyname : String) -> bool:
	var keycode = key_name_to_keycode(keyname)
	if Input.is_key_pressed(keycode):
		return true
	else:
		return false

func is_a_button_pressed(button : Button) -> bool:
	return button.button_pressed

func SetX(object : Node2D, action : String, x : int):
	match action:
		"=":
			object.global_position.x = x
		"+":
			object.global_position.x += x
		"-":
			object.global_position.x -= x
		"*":
			object.global_position.x *= x
		"/":
			object.global_position.x /= x

func SetY(object : Node2D, action : String, y : int):
	match action:
		"=":
			object.global_position.y = y
		"+":
			object.global_position.y += y
		"-":
			object.global_position.y -= y
		"*":
			object.global_position.y *= y
		"/":
			object.global_position.y /= y

func change_scene(SceneName : String):
	get_tree().change_scene_to_file("res://scene/" + SceneName + ".tscn")
	pass

func get_node_single(object_name: String) -> Node:
	var nodes = get_tree().get_nodes_in_group(object_name)
	if nodes.size() > 0:
		return nodes[0]
	return null

func trigger_once(trigger_once_id : int) -> bool:
	if !trigger_once_pool.has(trigger_once_id):
		trigger_once_pool.get_or_add(trigger_once_id,false)
		return true
	if trigger_once_pool[trigger_once_id] == true:
		trigger_once_pool[trigger_once_id] = false
		return true
	else:
		return false

func trigger_once_reset(trigger_once_id : int):
	if !trigger_once_pool.has(trigger_once_id):
		trigger_once_pool.get_or_add(trigger_once_id,true)
	else:
		trigger_once_pool[trigger_once_id] = true
		
func _show(node : Node):
	if node is Node2D or node is Node3D or node is Control:
		node.show()

func _hide(node : Node):
	if node is Node2D or node is Node3D or node is Control:
		node.show()

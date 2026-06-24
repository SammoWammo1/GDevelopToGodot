extends Control

var GDevelopDIR = ""
var GodotDIR = ""
var jsonfile = JSON.new()
var ObjectsToNode = {
	"TextObject::Text" = "Label",
	"Sprite" = "AnimatedSprite2D",
	"PanelSpriteButton::PanelSpriteButton" = "Button"
}
var fileaccessi = FileAccess.create_temp(FileAccess.WRITE_READ)
var addgdtogodotpopup := true
signal script_done

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_up"):
		$Conversion/Notes.set_position(Vector2($Conversion/Notes.position.x,$Conversion/Notes.position.y + 2))
	if Input.is_action_pressed("ui_down"):
		$Conversion/Notes.set_position(Vector2($Conversion/Notes.position.x,$Conversion/Notes.position.y - 2))


func GDevelopButton() -> void:
	$Main/GDevelop.show()
	$Main/Gdevelopbutton.text = "Change GDevelop folder"


func _on_GDevelop_dir_selected(dir: String) -> void:
	GDevelopDIR = dir


func _on_godot_dir_selected(dir: String) -> void:
	GodotDIR = dir


func _on_godotbutton_pressed() -> void:
	$Main/Godot.show()
	$Main/Godotbutton.text = "Change Godot folder"

func _begin_process() -> void:
	$Conversion.show()
	$Main.hide()
	jsonfile.parse(fileaccessi.get_file_as_string(GDevelopDIR + "/game.json"))
	var file_length = fileaccessi.get_file_as_string(GDevelopDIR + "/game.json")
	$Conversion/Notes.text += "Length of JSON: " + var_to_str(file_length.length()) + "\n"
	print("Length of JSON: " + var_to_str(file_length.length()))
	if fileaccessi.get_error() == OK:
		if jsonfile.data != null:
			$Conversion/Notes.text += "Found GDevelop JSON, parsed it.\n"
			var project_data: Dictionary = jsonfile.data
			if "layouts" in project_data:
				$Conversion/Notes.text += "Scenes found: " + var_to_str(project_data["layouts"].size()) + "\n"
				for n in project_data["layouts"].size():
					$Conversion/Notes.text += "Checking scene " + project_data["layouts"][n]["name"] + "\n"
					if "objects" in project_data["layouts"][n]:
						if GodotDIR != "":
							var dir = DirAccess.open(GodotDIR)
							dir.make_dir("scripts")
							dir.make_dir("objects")
							dir.make_dir("scene")
							dir.make_dir("assets")
							dir.change_dir(GodotDIR + "/assets/")
							dir.make_dir("sprites")
							$Conversion/Notes.text += "Adding resources.\n"
							for spr in project_data["resources"]["resources"]:
								if !spr["file"].contains("https://") and spr["kind"] == "image":
									var to_dir = GodotDIR + "/" + spr["file"]
									var from_dir = GDevelopDIR + "/" + spr["file"]
									print("FROM:", from_dir)
									print("TO:", to_dir)
									print("FROM:", from_dir)
									print("TO:", to_dir)
									print("From exists (OS path):", FileAccess.file_exists(from_dir))
									print("To exists (OS path):", FileAccess.file_exists(to_dir))
									# Make sure destination folder exists
									var to_folder = to_dir.get_base_dir()
									DirAccess.make_dir_recursive_absolute(to_folder)
									var err := DirAccess.rename_absolute(from_dir, to_dir)
									print("rename err:", err)
							dir.change_dir(GodotDIR + "/objects/")
							dir.make_dir(project_data["layouts"][n]["name"])
							for o in project_data["layouts"][n]["objects"].size():
								if !ObjectsToNode.has(project_data["layouts"][n]["objects"][o]["type"]):
									$Conversion/Notes.text += "Adding object " + project_data["layouts"][n]["objects"][o]["name"] + " failed, because the type doesn't exist.\n"
									continue
								$Conversion/Notes.text += "Adding object " + project_data["layouts"][n]["objects"][o]["name"] + " in " + project_data["layouts"][n]["name"] + "\n"
								var object = ClassDB.instantiate(ObjectsToNode[project_data["layouts"][n]["objects"][o]["type"]])
								var scene = PackedScene.new()
								object.name = "ToPack"
								if object is Label:
									object.text = project_data["layouts"][n]["objects"][o]["string"]
									object.add_theme_font_size_override("font_size", project_data["layouts"][n]["objects"][o]["characterSize"])
								elif object is AnimatedSprite2D:
									var spriteframes = SpriteFrames.new()
									var animaddloop : int = 0
									for a in project_data["layouts"][n]["objects"][o]["animations"]:
										print(a["name"], " has ", a["directions"][0]["sprites"].size(), " sprites")
										if a["name"] == "":
											$Conversion/Notes.text += "Skipping unnamed animation in " + project_data["layouts"][n]["objects"][o]["name"] + "\n"
											continue
										if animaddloop != 0:
											spriteframes.add_animation(a["name"])
										for spri in a["directions"][0]["sprites"]:
											var image = Image.load_from_file(GodotDIR + "/assets/" + spri["image"] + ".png")
											var texture = ImageTexture.create_from_image(image)
											if texture != null:
												if animaddloop != 0:
													spriteframes.add_frame(a["name"],texture)
													spriteframes.set_animation_speed(a["name"], 1.0 / a["directions"][0]["timeBetweenFrames"])
												else:
													spriteframes.add_frame("default",texture)
													spriteframes.set_animation_speed("default", 1.0 / a["directions"][0]["timeBetweenFrames"])
											else:
												$Conversion/Notes.text += "No texture found.\n"
										animaddloop += 1
									object.sprite_frames = spriteframes
									ResourceSaver.save(spriteframes,GodotDIR + "/assets/" + project_data["layouts"][n]["objects"][o]["name"] + ".tres")
								elif object is Button:
									object.text = project_data["layouts"][n]["objects"][o]["content"]["LabelText"]
								$ObjectToSpawn.add_child(object)
								object.owner = null
								scene.pack(object)
								ResourceSaver.save(scene, GodotDIR + "/objects/"+ project_data["layouts"][n]["name"] + "/" + project_data["layouts"][n]["objects"][o]["name"] + ".tscn")
								$ObjectToSpawn/ToPack.queue_free()
							dir.change_dir(GodotDIR + "/scene/")
							var createScene = PackedScene.new()
							$Conversion/Notes.text += "Now placing instances of objects of the scene " + project_data["layouts"][n]["name"] + "\n"
							for child in $Root/Scene.get_children():
								child.queue_free()
							var id = 0
							for l in project_data["layouts"][n]["instances"]:
								var packed = ResourceLoader.load(GodotDIR + "/objects/" + project_data["layouts"][n]["name"] + "/" +  l["name"] + ".tscn")
								if packed == null:
									$Conversion/Notes.text += "Object failed placing, doesn't exist!... moving on.\n"
									continue
								var instance = packed.instantiate()
								instance.name = l["name"] + "_" + var_to_str(id)
								id += 1
								$Root/Scene.add_child(instance)
								instance.position = Vector2(l["x"],l["y"])
								instance.z_index = int(l["zOrder"])
								instance.owner = $Root/Scene
								instance.add_to_group(l["name"], true)
							$Root/Scene.owner = null
							if addgdtogodotpopup != false:
								$Conversion/AcceptDialog.show()
								await $Conversion/AcceptDialog.confirmed
								addgdtogodotpopup = false
							$Conversion/Notes.text += "Converting events. (Oh boy.)\n"
							var scriptstr = write_script(project_data["layouts"][n]["name"], project_data["layouts"][n]["events"])
							var script = GDScript.new()
							script.source_code = scriptstr
							var err = script.reload()
							if err != OK:
								$Conversion/Notes.text += "SCRIPT COMPILE ERROR (code " + str(err) + ") ,so we can't attach it!\n"
								print("Script compile error: ", err)
								print(scriptstr)
							$Root/Scene.set_script(script)
							createScene.pack($Root/Scene)
							ResourceSaver.save(createScene, GodotDIR + "/scene/"+ project_data["layouts"][n]["name"] + ".tscn")
							for child in $Root/Scene.get_children():
								child.free()
							createScene = null
							$Conversion/Notes.text += "Events and scene placement should be done!\n"
						else:
							$Conversion/Notes.text += "You didn't set the Godot directory!\nThis conversion has failed. Please restart this tool."
							$Conversion/Label2.text = "Status: Failed"
					else:
						$Conversion/Notes.text += "Objects couldn't be found in the scene. This must mean this is a corrupt/incorrect game.json.\nThis conversion has failed. Please restart this tool."
						$Conversion/Label2.text = "Status: Failed"
			else:
				$Conversion/Notes.text += "No scenes were found. This must mean this is a corrupt/incorrect game.json.\nThis conversion has failed. Please restart this tool."
				$Conversion/Label2.text = "Status: Failed"
		else:
			$Conversion/Notes.text += "Parsing has failed. The file may be corrupt.\nThis conversion has failed. Please restart this tool."
			$Conversion/Label2.text = "Status: Failed"
	else:
		$Conversion/Notes.text += "No game.json file or it failed parsing.\nThis conversion has failed. Please restart this tool."
		$Conversion/Label2.text = "Status: Failed"


var event_counter := 0

func convert_expression(expr: String) -> String:
	expr = expr.replace("RandomFloatInRange(", "randf_range(")
	expr = expr.replace("RandomInRange(", "randi_range(")
	expr = expr.replace("ToString(", "str(")
	expr = expr.replace("ToNumber(", "float(")
	return expr

func gen_condition(instr_id: String, p: Array) -> String:
	match instr_id:
		"KeyFromTextPressed":
			return "GDtoGodot.is_key_pressed(\"%s\")" % p[1].replace("\"", "")
		"KeyFromTextJustPressed":
			return "GDtoGodot.is_key_pressed(\"%s\")" % p[1].replace("\"", "")
		"PanelSpriteButton::PanelSpriteButton::IsClicked":
			return "GDtoGodot.is_a_button_pressed(GDtoGodot.get_node_single(\"%s\") as Button)" % p[0].replace("\"", "")
		_:
			$Conversion/Notes.text += "Can't add " + instr_id +" as it is currently not implemented. Conversion will continue.\n"
			print(instr_id)
			return "false"

func gen_action(instr_id: String, p: Array) -> String:
	match instr_id:
		"SetX":
			return "GDtoGodot.SetX(GDtoGodot.get_node_single(\"%s\") as Node2D, \"%s\", %s)" % [p[0], p[1], convert_expression(p[2])]
		"SetY":
			return "GDtoGodot.SetY(GDtoGodot.get_node_single(\"%s\") as Node2D, \"%s\", %s)" % [p[0], p[1], convert_expression(p[2])]
		"Scene":
			return "GDtoGodot.change_scene(%s)" % [p[1]]
		"Show":
			return "GDtoGodot._show(GDtoGodot.get_node_single(%s))" % [p[0]]
		"Montre":
			return "GDtoGodot._show(GDtoGodot.get_node_single(%s))" % [p[0]]
		"Hide":
			return "GDtoGodot._hide(GDtoGodot.get_node_single(%s))" % [p[0]]
		_:
			$Conversion/Notes.text += "Can't add " + instr_id +" as it is currently not implemented. Conversion will continue.\n"
			print(instr_id)
			return "pass # TODO: " + instr_id

func gen_event(event: Dictionary) -> String:
	var event_id = event_counter
	event_counter += 1         

	var has_once = false
	var conds = []
	for c in event.get("conditions", []):
		var id = c["type"]["value"]
		if id == "BuiltinCommonInstructions::Once":
			has_once = true
		else:
			conds.append(gen_condition(id, c.get("parameters", [])))

	var cond_line = " and ".join(conds) if conds.size() > 0 else "true"

	var action_lines = []
	for a in event.get("actions", []):
		action_lines.append("\t\t" + gen_action(a["type"]["value"], a.get("parameters", [])))
	var actions_text = "\n".join(action_lines) if action_lines.size() > 0 else "\t\tpass"

	if has_once:
		return "if %s:\n\tif GDtoGodot.trigger_once(%d):\n%s\nelse:\n\tGDtoGodot.trigger_once_reset(%d)" % [cond_line, event_id, actions_text, event_id]
	else:
		return "if %s:\n%s" % [cond_line, actions_text]

func write_script(layout_name: String, events: Array) -> String:
	var blocks = []
	for event in events:
		blocks.append(gen_event(event))
	var body = "\n\n".join(blocks)

	var indented = []
	for line in body.split("\n"):
		indented.append("\t" + line if line.strip_edges() != "" else line)

	var full_script = "extends Node\n\nfunc _process(delta: float) -> void:\n" + "\n".join(indented)

	var file = FileAccess.open(GodotDIR + "/scripts/" + layout_name + ".gd", FileAccess.WRITE)
	file.store_string(full_script)
	file.close()
	script_done.emit()
	return full_script

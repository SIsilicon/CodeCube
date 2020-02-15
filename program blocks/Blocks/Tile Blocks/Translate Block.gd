extends ActionBlock

var string = "translate 0 0 0"

func _process(_delta : float) -> void:
	for spin_box in $Parameters.get_children():
		spin_box.mouse_filter = MOUSE_FILTER_IGNORE if \
				get_viewport().gui_is_dragging() else MOUSE_FILTER_STOP

func interpret() -> Array:
	var code := .interpret()
	if not code.empty() and code[0] == "already visited":
		return code
	
	code.append(string)
	
	if DEBUG_INTERPRET_STACK:
		prints("translate-block", string, self)
	
	var output_link := get_socket_link($Outflow)
	if output_link != -1:
		var next_block : ProgramBlock = program.get_socket(output_link, true).block
		code += next_block.interpret()
	
	return code

func serialize(blocks : Array) -> Dictionary:
	var dict := .serialize(blocks)
	dict.x = $Parameters/SpinBoxX.value
	dict.y = $Parameters/SpinBoxY.value
	dict.time = $Parameters/SpinBoxT.value
	
	return dict

func deserialize(dict : Dictionary) -> void:
	.deserialize(dict)
	$Parameters/SpinBoxX.value = dict.x
	$Parameters/SpinBoxY.value = dict.y
	$Parameters/SpinBoxT.value = dict.time
	
	_on_values_changed(0,0)

func _on_values_changed(_value : float, _param : int) -> void:
	string = "translate " + \
			str($Parameters/SpinBoxX.value) + " " + \
			str($Parameters/SpinBoxY.value) + " " + \
			str($Parameters/SpinBoxT.value)
	
	if program:
		program.code_dirty = true

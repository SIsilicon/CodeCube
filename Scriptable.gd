extends Spatial
class_name Scriptable

signal timeout()
signal read_instruction(line)

var program : CCProgram setget set_program
var executing := false
var line_num := 0

var loop_stack := []

var custom_insruction_set : FuncRef setget set_custom_instruction_set
var custom_blocks := []

var wait_time := 0.0

func execute() -> void:
	executing = true
	
	if not program:
		printerr("No program to run!")
		return
	elif program.error:
		printerr(CCProgram.get_error_msg(program.error))
		return
	
	line_num = 0
	while executing:
		var expression : String = program.code[line_num]
		emit_signal("read_instruction", line_num)
		
		var custom_executed := false
		if custom_insruction_set:
			var result = custom_insruction_set.call_func(expression)
			while result is GDScriptFunctionState:
				result = yield(result, "completed")
			custom_executed = result
		
		if not custom_executed:
			if expression == "stop":
				break
			elif expression.begins_with("wait "):
				var params := expression.split(" ")
				wait_time = float(params[1])
				yield(self, "timeout")
				
			elif expression.begins_with("loop count "):
				var count := int(expression.replace("loop count ", ""))
				loop_stack.push_back([line_num, "count", 0, count])
				yield(get_tree(), "idle_frame")
				
			elif expression == "loop forever":
				loop_stack.push_back([line_num, "forever"])
				yield(get_tree(), "idle_frame")
				
			elif expression == "loop end":
				match loop_stack[-1][1]:
					"count":
						if loop_stack[-1][2] < loop_stack[-1][3] - 1:
							line_num = loop_stack[-1][0]
							loop_stack[-1][2] += 1
						else:
							loop_stack.pop_back()
					"forever":
						line_num = loop_stack[-1][0]
				yield(get_tree(), "idle_frame")
				
			else:
				printerr("Runtime error! " + expression + " is not a valid command.")
				return
		
		line_num += 1
	
	executing = false

func _process(delta : float) -> void:
	if wait_time > 0:
		self.wait_time -= delta
		if wait_time <= 0:
			self.wait_time = 0
			emit_signal("timeout")

func reset() -> void:
	executing = false
	line_num = 0
	wait_time = 0

func set_program(value : CCProgram) -> void:
	program = value

func set_custom_instruction_set(value : FuncRef) -> void:
	custom_insruction_set = value

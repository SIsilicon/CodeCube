tool
extends Node

class_name State, "res://addons/node_fsm_plugin/state_icon.svg"

signal go_to

const AUTO_METHOD_PREFIX := 'go_to ' # Prefix for implicit state change
const AUTO_TARGET_METHOD_PREFIX := '.' # Prefix for implicit target method calls

enum StateType {NORMAL, PUSH}

export(String) var state_name : String = ''
export(StateType) var state_type : int

var fsm
var target : Node
var _timer : float = 0.0
var _timers : Dictionary = {}

func _get_configuration_warning() -> String:
	var warning : PoolStringArray = PoolStringArray()

	if get_script() == load("res://addons/node_fsm_plugin/state_node.gd"):
		warning.append('"%s" State must extend the script and not use it directly' % name)

	return warning.join('\n')

func get_state_name() -> String:
	if state_name:
		return state_name
	return name

func is_active_state() -> bool:
	return fsm.current_state == self and fsm.active

func reset_timer() -> void:
	_timer = 0.0

	# Reset all timers and re-register them to
	# allow randomized values to work correctly
	_timers.clear()
	on_timers_register()


func register_timer(method : String, timeout : float, timeout_end : float = 0) -> void:
	var timer_at : float = timeout
	if timeout_end:
		randomize()
		timer_at = rand_range(timeout, timeout_end)
	_timers[timer_at] = method

func _ready() -> void:
	if Engine.editor_hint:
		set_process_input(false)
		set_process(false)
		set_physics_process(false)
	else:
		on_ready()
		on_timers_register()

func _process(delta : float) -> void:
	_timer += delta
	_timers = _dispatch_timers()

func _dispatch_timers() -> Dictionary:
	var next_timers : Dictionary = {}
	for timer in _timers.keys():
		var timer_executed : bool = false

		if _timer > timer and is_active_state():
			var method_name : String = _timers[timer]

			if has_method(method_name):
				call(method_name)
				timer_executed = true

			elif method_name.begins_with(AUTO_METHOD_PREFIX):
				var state_name : String = method_name.lstrip(AUTO_METHOD_PREFIX)
				go_to(state_name)
				timer_executed = true

			elif method_name.begins_with(AUTO_TARGET_METHOD_PREFIX):
				var target_method_name : String  = method_name.lstrip(AUTO_TARGET_METHOD_PREFIX)
				target.call(target_method_name)
				timer_executed = true

		if not timer_executed:
			next_timers[timer] = _timers[timer]

	return next_timers

func _delete_executed_timer(key : float) -> void:
	_timers.erase(key)

# State transition methods
func go_to(state : String) -> void:
	emit_signal("go_to", state)

func go_to_previous() -> void:
	go_to(fsm.PREVIOUS)

# Behaviors to override
func on_timers_register() -> void:
	pass

func on_ready() -> void:
	pass

# NOTE: leaving 'target' not typed to avoid errors when
#		using typing in the extended scripts
func on_enter(target) -> void:
	pass

func on_exit(target) -> void:
	pass

func on_input(target, event : InputEvent) -> void:
	pass

func on_process(target, delta : float) -> void:
	pass

func on_physics_process(target, delta : float) -> void:
	pass

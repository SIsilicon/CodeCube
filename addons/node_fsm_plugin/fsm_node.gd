tool
extends Node

class_name FSM, "res://addons/node_fsm_plugin/fsm_icon.svg"

const PREVIOUS := 'previous'

export(bool) var active : bool = true
export var initial_state : String = ''

export(NodePath) onready var target : NodePath
onready var _target_node : Node = get_parent() as Node

var _states_map : Dictionary = {}
var _states_stack : Array = ['']
var current_state setget set_current_state
var active_state : String = ''

func _get_configuration_warning() -> String:
	var warning : PoolStringArray = PoolStringArray()
	if get_child_count() == 0:
		warning.append('%s should have at least a state node. please add some.' % name)

	if not initial_state:
		warning.append('%s should define an initial state' % name)
	else:
		# Check if the default is available in the list
		var state_found : bool = false
		for child in get_children():
			if initial_state == child.state_name or initial_state == child.name:
				state_found = true
		if not state_found:
			warning.append('%s has no "%s" state' % [name, initial_state])

	return warning.join('\n')

func set_current_state(state : String) -> void:
	if state and not _states_stack.front() == state:
		if current_state:
			current_state.on_exit(_target_node)

		if state == PREVIOUS:
			_states_stack.pop_front()

		else:
			var next_state : Node = _states_map.get(state)

			if not next_state.state_type == next_state.StateType.PUSH:
				_states_stack.pop_front()

			_states_stack.push_front(state)

		# Check if the state as connected and disconnect it
		if current_state and current_state.is_connected('go_to', self, '_on_State_go_to'):
			current_state.disconnect('go_to', self, '_on_State_go_to')

		current_state = _states_map.get(_states_stack.front())
		active_state = state # Update state name

		# Register the signal in the new state
		current_state.connect('go_to', self, '_on_State_go_to')

		current_state.on_enter(_target_node)

		if not state == 'previous':
			# Don't reset timers if coming from a 'PUSH' StateType
			current_state.reset_timer()

# External use to set state in a similar way from State node
func go_to(state : String) -> void:
	self.current_state = state

# Signal bind
func _on_State_go_to(state : String) -> void:
	go_to(state)

func in_states(states : Array = []) -> bool:
	return active_state in states

func get_all_states() -> Array:
	return _states_map.keys()

func _ready() -> void:
	if not Engine.editor_hint:
		if not target.is_empty():
			_target_node = get_node(target) as Node

		for child in get_children():
			child.fsm = self as FSM
			child.target = _target_node as Node
			_states_map[child.get_state_name()] = child as Node

		self.current_state = initial_state

	else:
		set_process(false)
		set_process_input(false)
		set_physics_process(false)

func _input(event : InputEvent) -> void:
	if active and current_state:
		current_state.on_input(_target_node, event)

func _process(delta : float) -> void:
	if active and current_state:
		current_state.on_process(_target_node, delta)

func _physics_process(delta : float) -> void:
	if active and current_state:
		current_state.on_physics_process(_target_node, delta)

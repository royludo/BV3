extends RigidBody2D

const BALL_START_POS_P1 : Vector2 = Vector2(330,360)
const BALL_START_POS_P2 : Vector2 = Vector2(730,360)

onready var last_transform = get_transform()
onready var last_linear_velocity = get_linear_velocity()
onready var last_angular_velocity = get_angular_velocity()


# use Player enum from globals
func constructor(player_side):
	if player_side == Globals.Player.P1:
		set_position(BALL_START_POS_P1)
	else:
		set_position(BALL_START_POS_P2)
	set_sleeping(true)


func set_last_variables(transform, linear, angular):
	last_transform = transform
	last_linear_velocity = linear
	last_angular_velocity = angular


func _integrate_forces(state):
	if Globals.is_online_multi and not get_tree().is_network_server():
		state.set_transform(last_transform)
		state.set_linear_velocity(last_linear_velocity)
		state.set_angular_velocity(last_angular_velocity)

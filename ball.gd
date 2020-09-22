extends RigidBody2D
class_name Ball

const BALL_MAX_SPEED:int = 1000

var ball_start_pos = {
	Globals.Team.TEAM_LEFT: Vector2(330,360),
	Globals.Team.TEAM_RIGHT: Vector2(730,360)
}

onready var last_transform = get_transform()
onready var last_linear_velocity = get_linear_velocity()
onready var last_angular_velocity = get_angular_velocity()

func constructor(side):
	set_position(ball_start_pos[side])
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

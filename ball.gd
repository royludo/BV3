extends RigidBody2D

const BALL_START_POS_P1 : Vector2 = Vector2(330,360)
const BALL_START_POS_P2 : Vector2 = Vector2(630,360)


# use Player enum from globals
func constructor(player_side):
	if player_side == Globals.Player.P1:
		set_position(BALL_START_POS_P1)
	else:
		set_position(BALL_START_POS_P2)
	set_sleeping(true)

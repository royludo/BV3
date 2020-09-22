extends KinematicBody2D
class_name Player

const WALK_FORCE = 500
const JUMP_FORCE = 850

# defaults values
var player_team = Globals.Team.TEAM_LEFT
var player_name = "Player 1"
 
onready var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 20
 
var velocity = Vector2()

puppet func setPosition(pos:Vector2):
	set_position(pos)
	
func constructor(player_name, player_team):
	self.player_name = player_name
	self.player_team = player_team
 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
 
	if Globals.is_online_multi:
		if is_network_master():
			process_input_and_move(delta)
			rpc_unreliable("setPosition", get_position())
	else:
		process_input_and_move(delta)

func process_input_and_move(delta):
	var walk = WALK_FORCE * (
		Input.get_action_strength("move_right") - 
		Input.get_action_strength("move_left")
		)
	
	velocity.y += gravity * delta
	velocity.x = walk
		
	move_and_slide(velocity, Vector2.UP)
 
func _input(event):
	if Globals.is_online_multi:
		if is_network_master():
			process_jump(event)
	else:
		process_jump(event)

func process_jump(event):
	if is_on_floor() && event.is_action_pressed("jump"):
		velocity.y = -JUMP_FORCE #+ gravity * delta

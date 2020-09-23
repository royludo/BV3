extends KinematicBody2D
class_name Player

const WALK_FORCE = 500
const JUMP_FORCE = 850

# defaults values
var player_team = Globals.Teams.TEAM_LEFT
var player_name = "Player 1"
 
onready var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 20
var default_shader = preload("res://blobby_shader.tres")
 
var velocity = Vector2()

puppet func setPosition(pos:Vector2):
	set_position(pos)
	
func constructor(name: String, team, color: Color):
	self.player_name = name
	self.player_team = team
	# print("constructor: " + str(player_name) + " " + str(player_team)+" "+str(Globals.TeamColor[player_team]))
	# print(str(default_shader))
	$Sprite.material = default_shader.duplicate()
	set_player_color(color)
	
func set_player_color(color: Color):
	$Sprite.material.set_shader_param("color", color)
 
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

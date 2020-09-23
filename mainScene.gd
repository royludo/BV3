extends Node2D


var ball_scene = load("res://ball.tscn")
onready var ball:RigidBody2D = $ball
onready var ball_y_size:int = ceil($ball/CollisionShape2D.shape.get_radius())
onready var arrow:Node2D = $ball_arrow
const TEAM_LEFT_PLAYER_START_POS:Vector2 = Vector2(200,400) 
const TEAM_RIGHT_PLAYER_START_POS:Vector2 = Vector2(800,400)

var TOO_CLOSE_COLLISION_FRAMES = 10
var X_COORD_MIDDLE_FIELD = 512
var MAX_TEAM_BALL_TOUCHES = 3
var END_PLAY_WAIT_TIME = 2.0

var touch_count_team_left:int = 0
var touch_count_team_right:int = 0
var last_team_touching
var score_team_left = 0
var score_team_right = 0
var is_end_play = false
var delta_count = 0
var last_body_touch

# Called when the node enters the scene tree for the first time.
func _ready():
	ball.connect("body_entered", self, "_on_ball_collision")
	
	Globals.players.clear()
	for pc in range(Globals.player_count):
		var p = preload("res://blobby.tscn").instance() as Player
		var name = "Player " + str(pc)
		var team = Globals.Teams.TEAM_LEFT
		if pc >= Globals.player_count/2:
			team = Globals.Teams.TEAM_RIGHT
		# print(str(pc)+" "+str(name)+" "+str(team))
		print()
		p.constructor(name, team, Globals.player_colors[pc])
		Globals.players.push_back(p)
	
	## init players ##
	if Globals.is_online_multi:
		Globals.players[0].set_name(str(get_tree().get_network_unique_id()))
		Globals.players[0].set_network_master(get_tree().get_network_unique_id())
		add_child(Globals.players[0])
		
		Globals.players[1].set_name(str(Globals.otherPlayerId))
		Globals.players[1].set_network_master(Globals.otherPlayerId)
		add_child(Globals.players[1])
		
		if get_tree().is_network_server():
			Globals.players[0].set_position(TEAM_RIGHT_PLAYER_START_POS)
			Globals.players[1].set_position(TEAM_LEFT_PLAYER_START_POS)
			Globals.players[1].player_team = Globals.Teams.TEAM_LEFT
			Globals.players[0].player_team = Globals.Teams.TEAM_RIGHT
			last_body_touch = Globals.players[0]
		else:
			Globals.players[0].set_position(TEAM_LEFT_PLAYER_START_POS)
			Globals.players[1].set_position(TEAM_RIGHT_PLAYER_START_POS)
			Globals.players[0].player_team = Globals.Teams.TEAM_LEFT
			Globals.players[1].player_team = Globals.Teams.TEAM_RIGHT
			last_body_touch = Globals.players[1]
		
		print("Created player for local with id: " + str(Globals.players[0].get_name()) + \
				" and player for remote with id: " + str(Globals.players[1].get_name()))
	else:
		Globals.players[0].set_position(TEAM_LEFT_PLAYER_START_POS)
		Globals.players[1].set_position(TEAM_RIGHT_PLAYER_START_POS)
		add_child(Globals.players[0])
		add_child(Globals.players[1])
		Globals.players[0].player_team = Globals.Teams.TEAM_LEFT
		Globals.players[1].player_team = Globals.Teams.TEAM_RIGHT

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# arrow indicator condition
	if ball.get_position().y < -ball_y_size:
		draw_ball_pointer_at(ball.get_position().x)
	else:
		arrow.set_visible(false)
		
	# print(ball.get_linear_velocity())


func _physics_process(delta):
	delta_count += 1
#	if Globals.is_online_multi:
#		if get_tree().is_network_server():
#			process_ball(delta)
#			rpc_unreliable("set_ball_position", ball.get_transform(), \
#			ball.linear_velocity, ball.angular_velocity)
#	else:
	process_ball(delta)
	

func process_ball(delta):
	# check if ball has glitched out of screen
	if ball.get_position().x < 0 \
	or ball.get_position().x > get_viewport().size.x \
	or ball.get_position().y > get_viewport().size.y:
		reset_play(Globals.Teams.TEAM_LEFT)
	
	# we need to cap the ball's max speed, it can go way too fast otherwise,
	# it's unmanageable for the player
	elif abs(ball.get_linear_velocity().x) > ball.BALL_MAX_SPEED \
	or abs(ball.get_linear_velocity().y) > ball.BALL_MAX_SPEED:
		var new_speed = ball.get_linear_velocity().normalized()
		new_speed *= ball.BALL_MAX_SPEED
		ball.set_linear_velocity(new_speed)
		

sync func set_ball_position(transform:Transform2D, linearVelocity:Vector2,\
angularVelocity):
	ball.set_last_variables(transform, linearVelocity, angularVelocity)
	pass

# arrow appears when ball leaves screen
func draw_ball_pointer_at(x):
	arrow.set_position(Vector2(x, 10))
	arrow.set_visible(true)

func reset_play(side):
	ball.queue_free() # destroy instance
	touch_count_team_left = 0
	touch_count_team_right = 0
	ball = ball_scene.instance()
	ball.constructor(side)
	add_child(ball) # mandatory after instance creation
	# forward collision detection from the ball to the mainScene
	ball.connect("body_entered", self, "_on_ball_collision")
	is_end_play = false

# redirected signal from the ball to here
func _on_ball_collision(body):
	if Globals.is_online_multi:
#		if get_tree().is_network_server():
#			process_ball_collision(body)
#			# rpc_unreliable("set_ball_position", ball.get_transform())
#			rpc_unreliable("set_ball_position", ball.get_transform(), \
#			ball.linear_velocity, ball.angular_velocity)
		process_ball_collision(body)
		#rpc_unreliable("set_ball_position", ball.get_transform(), \
		#ball.linear_velocity, ball.angular_velocity)
	else:
		process_ball_collision(body)
	
func process_ball_collision(body):
	if is_end_play:
		return
	print("collision with: " + str(body.get_name()))
	var other_team
	
	if Globals.is_online_multi and last_body_touch.is_network_master():
		print("I am " + str(get_tree().get_network_unique_id()) + " update ball pos")
		rpc_unreliable("set_ball_position", ball.get_transform(), \
		ball.linear_velocity, ball.angular_velocity)
			
	if body is TileMap and body.get_name() == "TileMapGround":
		# determine side where ball touched ground from its coords
		var side
		if ball.position.x < X_COORD_MIDDLE_FIELD:
			side = Globals.Teams.TEAM_LEFT
			other_team = Globals.Teams.TEAM_RIGHT
			score_team_right += 1
		else:
			side = Globals.Teams.TEAM_RIGHT
			other_team = Globals.Teams.TEAM_LEFT
			score_team_left += 1
		print("Touched ground on side: " + str(Globals.Teams.keys()[side]))
	elif body is KinematicBody2D:
		print(delta_count)
		if body == last_body_touch and delta_count < TOO_CLOSE_COLLISION_FRAMES:
			# if the same body touch the ball at too close interval
			# ignore the hit
			return
		delta_count = 0
		last_body_touch = body
		var player := body as Player
		
		# update who touched the ball and increment touch count
		last_team_touching = player.player_team
		if player.player_team == Globals.Teams.TEAM_LEFT:
			other_team = Globals.Teams.TEAM_RIGHT
			if touch_count_team_left == MAX_TEAM_BALL_TOUCHES:
				print("more than 3 touch TEAM_LEFT")
				touch_count_team_left = 0
				score_team_right += 1
			else:
				touch_count_team_left += 1
				touch_count_team_right = 0
				return
		else:
			other_team = Globals.Teams.TEAM_LEFT
			if touch_count_team_right == MAX_TEAM_BALL_TOUCHES:
				print("more than 3 touch TEAM_RIGHT")
				touch_count_team_right = 0
				score_team_left += 1
			else:
				touch_count_team_right += 1
				touch_count_team_left = 0
				return
	else:
		return
		
	update_score()
	is_end_play = true
	ball.set_collision_mask_bit(1, false) # no player collision
	ball.BALL_MAX_SPEED = 500 # slow down the ball
	yield(get_tree().create_timer(END_PLAY_WAIT_TIME), "timeout")
	call_deferred("reset_play", other_team)

	# VVVV    dangerous! do not uncomment!     VVVV
	# print("last team touching: " + \
	# str(Globals.Team.keys()[last_team_touching]) + " " + \
	# str(touch_count_team_left) + " " + str(touch_count_team_right))

puppet func update_score_remote(score_left, score_right):
	$ScoreTeamLeft.set_text(str(score_left))
	$ScoreTeamRight.set_text(str(score_right))

func update_score():
	$ScoreTeamLeft.set_text(str(score_team_left))
	$ScoreTeamRight.set_text(str(score_team_right))
	if Globals.is_online_multi and get_tree().is_network_server():
		rpc("update_score_remote", score_team_left, score_team_right)

func _input(event):
	if event.is_action_pressed("menu"):
		get_tree().change_scene("res://mainMenu.tscn")

extends Node2D


var ball_scene = load("res://ball.tscn")
var ball:RigidBody2D
var ball_y_size:int
var arrow:Node2D
const BALL_MAX_SPEED:int = 1000
const P1_START_POS:Vector2 = Vector2(200,400) 
const P2_START_POS:Vector2 = Vector2(800,400)

var touch_count_P1:int = 0
var touch_count_P2:int = 0
var P1_blobby:KinematicBody2D
var P2_blobby:KinematicBody2D
var last_player_touching
var next_player
var score_P1 = 0
var score_P2 = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	#get and init ball object
	ball = get_node("ball")
	ball_y_size = ceil(get_node("ball/CollisionShape2D").shape.get_radius())
	init_ball()
	
	arrow = get_node("ball_arrow")
	
	## init players ##
	if Globals.is_online_multi:
		var my_player = preload("res://blobby.tscn").instance()
		my_player.set_name(str(get_tree().get_network_unique_id()))
		my_player.set_network_master(get_tree().get_network_unique_id())
		add_child(my_player)
		
		var other_player = preload("res://blobby.tscn").instance()
		other_player.set_name(str(Globals.otherPlayerId))
		other_player.set_network_master(Globals.otherPlayerId)
		add_child(other_player)
		
		if get_tree().is_network_server():
			P1_blobby = my_player
			my_player.set_position(P1_START_POS)
			P2_blobby = other_player
			other_player.set_position(P2_START_POS)
		else:
			P2_blobby = my_player
			my_player.set_position(P2_START_POS)
			P1_blobby = other_player
			other_player.set_position(P1_START_POS)
		
		print("Created player for local with id: " + str(my_player.get_name()) + \
		" and player for remote with id: " + str(other_player.get_name()))
	else:
		var player = preload("res://blobby.tscn").instance()
		player.set_name("blobby")
		P1_blobby = player
		player.set_position(P1_START_POS)
		add_child(player)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# arrow indicator condition
	if ball.get_position().y < -ball_y_size:
		draw_ball_pointer_at(ball.get_position().x)
	else:
		arrow.set_visible(false)
		
	#print(ball.get_linear_velocity())


func _physics_process(delta):
	if Globals.is_online_multi:
		if get_tree().is_network_server():
			process_ball(delta)
			rpc_unreliable("set_ball_position", ball.get_transform(), \
			ball.linear_velocity, ball.angular_velocity)
	else:
		process_ball(delta)
	

func process_ball(delta):
	# we need to cap the ball's max speed, it can go way too fast otherwise,
	# it's unmanageable for the player
	if abs(ball.get_linear_velocity().x) > BALL_MAX_SPEED \
	or abs(ball.get_linear_velocity().y) > BALL_MAX_SPEED:
		var new_speed = ball.get_linear_velocity().normalized()
		new_speed *= BALL_MAX_SPEED
		ball.set_linear_velocity(new_speed)
		
	# check if ball has glitched out of screen
	if ball.get_position().x < 0 \
	or ball.get_position().x > get_viewport().size.x \
	or ball.get_position().y > get_viewport().size.y:
		destroy_and_reset_ball_at(Globals.Player.P1)

puppet func set_ball_position(transform:Transform2D, linearVelocity:Vector2,\
angularVelocity):
	ball.set_transform(transform)
	ball.set_linear_velocity(linearVelocity)
	ball.set_angular_velocity(angularVelocity)

# arrow appears when ball leaves screen
func draw_ball_pointer_at(x):
	arrow.set_position(Vector2(x, 10))
	arrow.set_visible(true)
	pass

func destroy_and_reset_ball_at(player):
	ball.queue_free() # destroy instance
	reset_score()
	create_ball_at(player)

# forward collision detection from the ball to the mainScene
func init_ball():
	ball.connect("body_entered", self, "_on_ball_collision")

func create_ball_at(player):
	ball = ball_scene.instance()
	ball.constructor(Globals.Player.P1)
	add_child(ball) # mandatory after instance creation
	init_ball()

# redirected signal from the ball to here
func _on_ball_collision(body):
	if Globals.is_online_multi:
		if get_tree().is_network_server():
			process_ball_collision(body)
			#rpc_unreliable("set_ball_position", ball.get_transform())
	else:
		process_ball_collision(body)
	
func process_ball_collision(body):
	print("collision with: " + str(body.get_name()))
	if body is TileMap and body.get_name() == "TileMapGround":
		# determine side where ball touched ground from its coords
		var side
		if ball.position.x < 512:
			side = Globals.Player.P1
			score_P2 += 1
		else:
			side = Globals.Player.P2
			score_P1 += 1
			
		print("Touched ground on side: " + str(Globals.Player.keys()[side]))
		update_score()
		call_deferred("destroy_and_reset_ball_at", last_player_touching)
		
	if body is KinematicBody2D:
		# check player exceeding their touch limits
		if touch_count_P1 >= 3:
			call_deferred("destroy_and_reset_ball_at", Globals.Player.P2)
			touch_count_P1 = 0
			score_P2 += 1
			update_score()
		
		if touch_count_P2 >= 3:
			call_deferred("destroy_and_reset_ball_at", Globals.Player.P1)
			touch_count_P2 = 0
			score_P1 += 1
			update_score()
		
		# update who touched the ball and increment touch count
		if body == P1_blobby:
			last_player_touching = Globals.Player.P1
			next_player = Globals.Player.P2
			touch_count_P1 += 1
			touch_count_P2 = 0
		else:
			last_player_touching = Globals.Player.P2
			next_player = Globals.Player.P1
			touch_count_P2 += 1
			touch_count_P1 = 0
		
		print("last player touching: " + \
		str(Globals.Player.keys()[last_player_touching]) + " " + \
		"next_player: " + str(Globals.Player.keys()[next_player]) + " " +\
		str(touch_count_P1) + " " + str(touch_count_P2))

func reset_score():
	touch_count_P1 = 0
	touch_count_P2 = 0

func update_score():
	$ScoreP1.set_text(str(score_P1))
	$ScoreP2.set_text(str(score_P2))

func _input(event):
	if event.is_action_pressed("menu"):
		get_tree().change_scene("res://mainMenu.tscn")

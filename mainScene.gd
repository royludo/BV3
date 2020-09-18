extends Node2D


var ball_scene = load("res://ball.tscn")
var ball : RigidBody2D
var ball_y_size : int
var arrow : Node2D
var ball_start_pos : Vector2 = Vector2(330,360)
const BALL_MAX_SPEED : int = 1000
const P1_START_POS:Vector2 = Vector2(200,400) 
const P2_START_POS:Vector2 = Vector2(800,400)

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
			my_player.set_position(P1_START_POS)
			other_player.set_position(P2_START_POS)
		else:
			my_player.set_position(P2_START_POS)
			other_player.set_position(P1_START_POS)
		
		print("Created player for local with id: " + str(my_player.get_name()) + \
		" and player for remote with id: " + str(other_player.get_name()))
	else:
		var player = preload("res://blobby.tscn").instance()
		player.set_name("blobby")
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
			rpc_unreliable("set_ball_position", ball.get_transform())
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
		print("OUUUUUT!!")
		ball.queue_free() # destroy instance
		ball = ball_scene.instance()
		add_child(ball) # mandatory after instance creation
		init_ball()

puppet func set_ball_position(transform:Transform2D):
	ball.set_transform(transform)

func _input(event):
	if event.is_action_pressed("menu"):
		get_tree().change_scene("res://mainMenu.tscn")

# arrow appears when ball leaves screen
func draw_ball_pointer_at(x):
	arrow.set_position(Vector2(x, 10))
	arrow.set_visible(true)
	pass

func init_ball():
	ball.set_position(ball_start_pos)
	ball.set_sleeping(true)

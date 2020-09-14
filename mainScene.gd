extends Node2D


var ball_scene = load("res://ball.tscn")
var ball : RigidBody2D
var ball_y_size : int
var arrow : Node2D
var ball_start_pos : Vector2 = Vector2(330,360)
const BALL_MAX_SPEED : int = 1000

# Called when the node enters the scene tree for the first time.
func _ready():
	
	#get and init ball object
	ball = get_node("ball")
	ball_y_size = ceil(get_node("ball/CollisionShape2D").shape.get_radius())
	init_ball()
	
	arrow = get_node("ball_arrow")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# arrow indicator condition
	if ball.get_position().y < -ball_y_size:
		draw_ball_pointer_at(ball.get_position().x)
	else:
		arrow.set_visible(false)
		
	#print(ball.get_linear_velocity())


func _physics_process(delta):
	
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

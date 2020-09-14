extends KinematicBody2D

const WALK_FORCE = 500
const JUMP_FORCE = 850
 
onready var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 15
 
var velocity = Vector2()
 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
 
	var walk = WALK_FORCE * (
		Input.get_action_strength("move_right") - 
		Input.get_action_strength("move_left")
		)
	
	velocity.y += gravity * delta
	velocity.x = walk
	
	move_and_slide(velocity, Vector2.UP)

 
func _input(event):
	if is_on_floor() && event.is_action_pressed("jump"):
			velocity.y = -JUMP_FORCE #+ gravity * delta

extends AnimatedSprite


var target = null
var speed = GlobalData.MISSILE_SPEED
var active = true

func _physics_process(delta):
	if target != null and active and is_instance_valid(target):
		if global_position.distance_to(target.global_position) > 5:
			global_position = global_position.move_toward(target.global_position, speed)
			look_at(target.global_position)
		else:
			target.damage(GlobalData.MISSILE_DAMAGE)
			active = false
			explode()
	else:
		explode()

func explode():
	play("explode")
	yield(self, "animation_finished")
	queue_free()

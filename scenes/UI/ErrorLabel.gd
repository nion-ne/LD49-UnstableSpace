extends Label

onready var anim = $AnimationPlayer

func _ready():
	hide()

func show_error(msg):
	show()
	text = msg
	anim.play("Fade")
	yield(anim, "animation_finished")
	hide()

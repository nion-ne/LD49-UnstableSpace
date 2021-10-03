extends Control


onready var label = $RichTextLabel
onready var audio_alert = $AudioAlert
onready var timer = $Timer 

var typing = false
var curr_msg = ""
var typing_index = 0
var cooldown = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	if typing and typing_index < curr_msg.length() and not cooldown:
		label.text += curr_msg[typing_index]
		typing_index += 1
		if typing_index == curr_msg.length():
			typing = false
		cooldown = true
		timer.start(0.02)
		yield(timer, "timeout")
		cooldown = false


func add_msg(msg):
#	label.text += "> " + msg + "\n"
	curr_msg = "> " + msg + "\n"
	typing_index = 0
	typing = true
	audio_alert.play()
	#Make sound

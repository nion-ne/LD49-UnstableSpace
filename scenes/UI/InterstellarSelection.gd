extends Control


onready var title_label = $TitleLabel
onready var subtitle_label = $SubtitleLabel
onready var error_label = $ErrorLabel
onready var error_anim = $ErrorLabel/AnimationPlayer

var active = false
var current_interstellar_child = null

func _ready():
	deactivate()

func activate(interstellar_child):
	active = true
	subtitle_label.text = "Right click a star to send " + interstellar_child.title + " to."
	interstellar_child.currently_orbiting.show_neighbour_lines()
	current_interstellar_child = interstellar_child
	show()

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_LEFT:# or event.button_index == BUTTON_RIGHT:
				if active:
					deactivate()

func star_targeted(star):
	
	if not star.discovered:
		if not current_interstellar_child.is_in_group("scouts"):
#			error_anim.play("Fade")
			current_interstellar_child.currently_orbiting.hide_neighbour_lines()
			get_parent().error_alert.show_error("Undiscovered star\nSend scout ship first.")
			deactivate()
			return
	
	print("star targeted for FTL")
	current_interstellar_child.activate_FTL(star)
	deactivate()


func deactivate():
	if current_interstellar_child != null:
		current_interstellar_child.unselect()
	active = false
	hide()

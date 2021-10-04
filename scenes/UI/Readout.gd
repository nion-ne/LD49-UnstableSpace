extends Node2D


onready var anim_player = $AnimationPlayer
onready var target_name = $TargetName
onready var details = $Details

const TEXT_SPEED = 1.0

var target = null
var active = false


func _ready():
	hide()

func _process(delta):
	if active and target != null and is_instance_valid(target):
		position = target.get_global_transform_with_canvas().origin
	else:
		deactivate()
		
func _physics_process(delta):
	if active and target != null and is_instance_valid(target):
		target_name.percent_visible += (1.0 / target_name.text.length() * TEXT_SPEED / 2)
		details.percent_visible += (1.0 / details.text.length() * TEXT_SPEED)

func activate(_target):
	target = _target
	load_details()
	active = true
	show()
	anim_player.play("swipe_in")
	
	target_name.percent_visible = 0
	details.percent_visible = 0
	
#	details.text = _target

func load_details():
	target_name.text = "???"
	details.text = "???"
	if target == null:
		return
	if target.is_in_group("stars"):

		var discovered = target.discovered
		var num_planets = target.num_planets
		var luminosity = target.luminosity
		var ships = target.get_ships()
		var build_ships = 0
		var combat_ships = 0
		var scout_probes = 0
		for ship in ships:
			if ship.is_in_group("builders"): build_ships += 1
			elif ship.is_in_group("scouts"): scout_probes += 1
			elif ship.is_in_group("combat"): combat_ships += 1
		
		if target.discovered:
			target_name.text = target.star_name
			details.text = ""
			details.text += "Planets: " + str(num_planets) + "\n"
			details.text += "Luminosity: " + str(luminosity) + "\n"
			details.text += "Builders: " + str(build_ships) + "\n"
			details.text += "Scouts: " + str(scout_probes) + "\n"
			details.text += "Fighters: " + str(combat_ships) + "\n"
		
	elif target.is_in_group("planets"):
		target_name.text = target.name
		details.text = ""
		details.text += "Metalicity: " + str(target.metalicity) + "\n"
		details.text += "Build slots: " + str(target.used_slots) + "/" + str(target.max_slots) + "\n"
		details.text += "Brightness: " + str(target.brightness) + "\n"
	elif target.is_in_group("ships"):
		target_name.text = target.title
		details.text = ""
		details.text += "Status: " + str(target.STATUSES.keys()[target.current_status]) + "\n"


func deactivate():
	active = false
	target = null
	hide()

extends Control

onready var planet_build = $PlanetBuild
onready var ship_build = $ShipBuild
onready var build_label = $BuildLabel

onready var miner_icon = $PlanetBuild/MinerIcon
onready var solar_icon = $PlanetBuild/SolarIcon
onready var scout_icon = $ShipBuild/ScoutIcon
onready var builder_icon = $ShipBuild/BuilderIcon
onready var fighter_icon = $ShipBuild/FighterIcon

enum MODES {INACTIVE, PLANET, SHIP}
var curr_mode = MODES.INACTIVE

var curr_target = null

func _ready():
	show()
	deactivate()
	
	for icon in planet_build.get_children():
		icon.connect("gui_input", self, "on_icon_input_event", [icon])
	for icon in ship_build.get_children():
		icon.connect("gui_input", self, "on_icon_input_event", [icon])

func _process(delta):
	if not is_instance_valid(curr_target):
		deactivate()
	match curr_mode:
		MODES.PLANET:
			if is_valid_option(miner_icon, curr_target):
				miner_icon.modulate = Color.white
			else:
				miner_icon.modulate = Color(1,1,1,0.3)
			if is_valid_option(solar_icon, curr_target):
				solar_icon.modulate = Color.white
			else:
				solar_icon.modulate = Color(1,1,1,0.3)
		MODES.SHIP:
			if is_valid_option(builder_icon, curr_target):
				builder_icon.modulate = Color.white
			else:
				builder_icon.modulate = Color(1,1,1,0.3)
			if is_valid_option(scout_icon, curr_target):
				scout_icon.modulate = Color.white
			else:
				scout_icon.modulate = Color(1,1,1,0.3)
			if is_valid_option(fighter_icon, curr_target):
				fighter_icon.modulate = Color.white
			else:
				fighter_icon.modulate = Color(1,1,1,0.3)
func activate(target):
	if target.is_in_group("planets"):
		curr_mode = MODES.PLANET
		planet_build.show()
		ship_build.hide()
		build_label.text = "BUILD/PLANET"
		build_label.show()
		
#		if target.used_slots >= target.max_slots:
#			planet_build.modulate = Color(1,1,1,0.3)
#		else:
#			planet_build.modulate = Color.white
		
	elif target.is_in_group("builders"):
		curr_mode = MODES.SHIP
		ship_build.show()
		planet_build.hide()
		build_label.text = "BUILD/SHIP"
		build_label.show()
	curr_target = target

func deactivate():
	curr_mode = MODES.INACTIVE
	ship_build.hide()
	planet_build.hide()
	build_label.hide()
	curr_target = null

func is_valid_option(icon, target):
	match icon:
		miner_icon:
			return target.can_build("miner")
		solar_icon:
			return target.can_build("solar")
		builder_icon:
			return target.can_build("builder")
		scout_icon:
			return target.can_build("scout")
		fighter_icon:
			return target.can_build("fighter")

func on_icon_input_event(event, source):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.is_pressed():
		
		if curr_target != null and is_instance_valid(curr_target):
			if is_valid_option(source, curr_target):

				match source:
					builder_icon:
						curr_target.build_ship("builder")
					scout_icon:
						curr_target.build_ship("scout")
					fighter_icon:
						curr_target.build_ship("fighter")
					miner_icon:
						curr_target.build("miner")
					solar_icon:
						curr_target.build("solar")
#				if source == builder_icon:
#					curr_target.build_ship("builder")

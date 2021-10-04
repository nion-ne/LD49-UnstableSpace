extends Control


onready var star_name = $StarName
onready var metal_text = $HBoxContainer/MetalText
onready var energy_text = $HBoxContainer/EnergyText
onready var galaxy = get_tree().get_nodes_in_group("galaxy")[0]

var active = false

func _ready():
	deactivate()

func _process(delta):
	if active and galaxy.active_star != null and is_instance_valid(galaxy.active_star):
		metal_text.text = "Metal: " + str(galaxy.active_star.metal).pad_decimals(0)
		energy_text.text = "Energy: " + str(galaxy.active_star.energy).pad_decimals(0)
		
func activate():
	active = true
	if galaxy.active_star != null and is_instance_valid(galaxy.active_star):
		star_name.text = galaxy.active_star.star_name
	show()
	
func deactivate():
	active = false
	hide()

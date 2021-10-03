extends Node2D

const PLANET = preload("res://scenes/stars/Planet.tscn")
const TARGET_VECTOR = preload("res://scenes/TargetVector.tscn")

onready var canvas_layer = $CanvasLayer
onready var stars = $Stars.get_children()

var selected_star = null
var last_selected_star = null
var active_star = null
var interstellar_child

var enemy_initialised = false

func _ready():
	print("Setting all stars to discovered and wealthy for debug")
	for star in stars:
		if star.name == "Star":
			star.discovered = true
			star.energy = 100
			star.metal = 100
			star.add_start_ship()
			star.set_ownership("player")
#		star.discovered = true
	
	MissionHandler.intro_dialogue()


func _process(delta):
	if Input.is_action_just_pressed("debug"):
		for star in stars:
			star.metal = 99999
			star.energy = 99999
			star.discovered = true
#			star.set_ownership("player")
	if get_tree().get_nodes_in_group("enemy_AI").empty() and enemy_initialised:
		canvas_layer.error_alert.show_error("Victory!?")
		
	var num_player_stars = 0
	for s in get_tree().get_nodes_in_group("stars"):
		if s.owned_by == "player":
			num_player_stars += 1
	if not enemy_initialised and num_player_stars >= 3 and get_tree().get_nodes_in_group("builders").size() >= 3 and game_setup == false:
		print("start war")
		game_setup = true
		MissionHandler.start_war()
		
var game_setup = false


func unselect_star():
	if selected_star != null:
		selected_star.unselect()
		selected_star = null
	canvas_layer.readout.deactivate()

func select_star(target):
	if selected_star != target:
		unselect_star()
	last_selected_star = selected_star
	selected_star = target
	
#	canvas_layer.readout.position = target.get_global_transform_with_canvas().origin
	canvas_layer.readout.activate(target)

func set_active_star(target):
	active_star = target
#	select_star(target)
	unselect_star()
	canvas_layer.system_details.activate()
	clear_interstellar_child()

func create_target_vector_at(pos):
	var target_vector = TARGET_VECTOR.instance()
	target_vector.global_position = pos
	add_child(target_vector)
	return target_vector

func set_interstellar_child(_interstellar_child):
	interstellar_child = _interstellar_child
	canvas_layer.interstellar_selection.activate(interstellar_child)

func clear_interstellar_child():
	canvas_layer.interstellar_selection.deactivate()
	interstellar_child = null


	

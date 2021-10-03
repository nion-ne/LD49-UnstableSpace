extends Node2D


onready var galaxy = get_tree().get_nodes_in_group("galaxy")[0]
onready var sprite = $Sprite
onready var progress = $Progress
onready var timer = $Timer

onready var slot1 = $BuildSlots/Slot1
onready var slot2 = $BuildSlots/Slot2
onready var slot3 = $BuildSlots/Slot3

var selected = false

enum TYPES { UNKNOWN, SMALL, MEDIUM, LARGE, GAS}
var type = TYPES.UNKNOWN
enum STATUSES {IDLE, WAITING, BUILDING}
var current_status = STATUSES.IDLE

export var brightness = 1.0
export var max_slots = -1
export var used_slots = 0
export var metalicity = 1.0

export var slots = ["", "", ""]

var parent_star
var build_time = -1

func _ready():
	progress.hide()

	brightness = inverse_lerp(200, 30, position.distance_to(Vector2(0, 0)))
	brightness = lerp(0.5, 1, brightness) * (parent_star.luminosity / 10)
	
func _process(delta):
	match current_status:
		STATUSES.BUILDING:
			progress.value = ((build_time - timer.time_left) / build_time) * 100.0
	
	for s in slots:
		if s == "miner":
			parent_star.metal += (GlobalData.MINE_RATE * (metalicity / 10)) * delta
		elif s == "solar":
			parent_star.energy += (GlobalData.SOLAR_RATE * brightness) * delta
	
func setup(order):
	sprite = $Sprite
	
	match order:
		1:
			type = TYPES.keys()[randi() % 2 + 2]
		2:
			type = TYPES.keys()[randi() % 4 + 1]
		3:
			type = TYPES.keys()[randi() % 4 + 1]
		4:
			type = TYPES.keys()[randi() % 4 + 1]
		5:
			type = TYPES.keys()[randi() % 4 + 1]

	match TYPES[type]:
		TYPES.SMALL:
			sprite.scale = sprite.scale * 0.8
			max_slots = 1
		TYPES.MEDIUM:
			max_slots = 2
		TYPES.LARGE:
			sprite.scale = sprite.scale * 1.2
			max_slots = 3
		TYPES.GAS:
			sprite.scale = sprite.scale * 1.5
			max_slots = 0
			sprite.play("gas" + str(randi() % 2 + 1))
			metalicity = 0
	name = type + " " + str(order)
	
	metalicity = metalicity * rand_range(5, 15)

func can_build(type):
	if current_status != STATUSES.IDLE:
		return false
	match type:
		"miner":
			if used_slots >= max_slots:
				return false
			if not parent_star.has_available_builder():
				return false
			if parent_star.metal < GlobalData.MINE_METAL_COST:
				return false
			if parent_star.energy < GlobalData.MINE_ENERGY_COST:
				return false
			return true
		"solar":
			if used_slots >= max_slots:
				return false
			if not parent_star.has_available_builder():
				return false
			if parent_star.metal < GlobalData.SOLAR_METAL_COST:
				return false
			if parent_star.energy < GlobalData.SOLAR_ENERGY_COST:
				return false
			return true

func select():
	selected = true
	parent_star.select_child(self)
	
	if TYPES[type] != TYPES.GAS:
		galaxy.canvas_layer.build_menu.activate(self)
	else:
		galaxy.canvas_layer.build_menu.deactivate()

func build(type):
	
	build_time = 1
	match type:
		"miner": build_time = GlobalData.MINE_BUILD_TIME
		"solar": build_time = GlobalData.SOLAR_BUILD_TIME
	print("Building " + type)
	
	var builder = parent_star.recruit_builder()
	if not builder:
		print("Error recruiting builder...")
		return
	builder.summon(self)
	current_status = STATUSES.WAITING
	yield(builder, "arrived_to_destination")
	current_status = STATUSES.BUILDING
	builder.current_status = builder.STATUSES.BUILDING
	builder.build_time = build_time
	builder.timer.start(build_time)
	galaxy.canvas_layer.readout.load_details()
	builder.progress.show()
	
	yield(builder.timer, "timeout")
	if current_status != STATUSES.BUILDING:
		return
	
	match type:
		"miner":
			parent_star.metal -= GlobalData.MINE_METAL_COST
			parent_star.energy -= GlobalData.MINE_ENERGY_COST
		"solar": 			
			parent_star.metal -= GlobalData.SOLAR_METAL_COST
			parent_star.energy -= GlobalData.SOLAR_ENERGY_COST
	
	used_slots += 1
	builder.progress.hide()
	current_status = STATUSES.IDLE
	builder.current_status = STATUSES.IDLE
	builder.destination = null
	galaxy.canvas_layer.readout.load_details()
	# Add sprite
	
	match int(used_slots):
		1: 
			slot1.play(type)
			slot1.show()
			slots[0] = type
		2: 
			slot2.play(type)
			slot2.show()
			slots[1] = type
		3: 
			slot3.play(type)
			slot3.show()
			slots[2] = type

func unselect():
	selected = false
#	selection_sprite.hide()

func _on_Area2D_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.is_pressed():
		if not selected and current_status != STATUSES.BUILDING and parent_star.owned_by == "player":
			select()

func remove_buildings():
	slots = ["", "", ""]
	used_slots = 0
	slot1.hide()
	slot2.hide()
	slot3.hide()

func get_num_miners():
	var m = 0
	if slots[0] == "miner": m += 1
	if slots[1] == "miner": m += 1
	if slots[2] == "miner": m += 1
	return m
	
func get_num_solar():
	var s = 0
	if slots[0] == "solar": s += 1
	if slots[1] == "solar": s += 1
	if slots[2] == "solar": s += 1
	return s

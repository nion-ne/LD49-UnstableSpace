extends Node2D

onready var decision_timer = $DecisionTimer
onready var star = get_parent()

enum STATES {RESOURCES, MILITARY, SCOUT, ATTACK, SPREAD}
var current_state = STATES.RESOURCES

var decision_cooldown = false
var active_builder = null
var new_builder = null

var vacant_neighbours = []
var occupied_neighbours = []

func _ready():
	update_builder()
	if active_builder != null and is_instance_valid(active_builder):
		do_action()

func _process(delta):
	pass

func do_action():
	match current_state:
		STATES.RESOURCES:
			if not is_builder_available():
				decision_timer.start(GlobalData.AI_DECISION_TIME)
				return
			
			var miners = get_num_miners()
			var solars = get_num_solar()
			if miners == 0:
				build_on_planet("miner")
				decision_timer.start(GlobalData.AI_DECISION_TIME)
				return
			elif solars == 0:
				build_on_planet("solar")
				decision_timer.start(GlobalData.AI_DECISION_TIME)
				return
			
			if get_num_fighters() < 3:
				current_state = STATES.MILITARY
				decision_timer.start(0.1)
				return
			else:
				if miners <= solars:
					build_on_planet("miner")
				else:
					build_on_planet("solar")
			
			current_state = STATES.MILITARY
			decision_timer.start(GlobalData.AI_DECISION_TIME)
			
				
		STATES.MILITARY:
			
			if not is_builder_available():
				decision_timer.start(GlobalData.AI_DECISION_TIME)
				return
			
			if get_num_fighters() >= 3 and vacant_neighbours.empty():
				current_state = STATES.SCOUT
				decision_timer.start(GlobalData.AI_DECISION_TIME)
				return
			elif get_num_fighters() >= 3 and not vacant_neighbours.empty():
				current_state = STATES.SPREAD
				decision_timer.start(GlobalData.AI_DECISION_TIME)
				return
		
			if active_builder.can_build("fighter"):
				build_ship("fighter")
				current_state = STATES.RESOURCES
				decision_timer.start(GlobalData.AI_DECISION_TIME)
				return
			else:
				decision_timer.start(GlobalData.AI_DECISION_TIME)
				return
			
		STATES.SCOUT:
			
			
			if get_num_scouts() == 0:
				if not is_builder_available():
					decision_timer.start(GlobalData.AI_DECISION_TIME)
					return
				
				if active_builder.can_build("scout"):
					build_ship("scout")
					decision_timer.start(GlobalData.AI_DECISION_TIME)
					return
				else:
					decision_timer.start(GlobalData.AI_DECISION_TIME)
					return
				current_state = STATES.RESOURCES
				decision_timer.start(GlobalData.AI_DECISION_TIME)
				return
			
			var neighbour = get_rand_neighbour()
			if neighbour.owned_by == "player":
				attack_target(neighbour)
				current_state = STATES.RESOURCES
				decision_timer.start(GlobalData.AI_DECISION_TIME)
				return
				
			elif neighbour.owned_by == "enemy":
				current_state = STATES.RESOURCES
				decision_timer.start(GlobalData.AI_DECISION_TIME)
				return
			else:
				scout_target(neighbour)
				current_state = STATES.RESOURCES
				decision_timer.start(GlobalData.AI_DECISION_TIME)
				return
			
		STATES.SPREAD:

			if not is_builder_available():
				decision_timer.start(GlobalData.AI_DECISION_TIME)
				return
			
			if get_num_builders() > 1:
				for s in star.get_ships():
					if s.is_in_group("builders"):
						if s.is_in_group("enemy"):
							if s != active_builder:
								new_builder = s
				new_builder.mission_active = true
				new_builder.activate_FTL(vacant_neighbours.pop_front())
				new_builder = null
				print("SENDING BUILDER TO OTHER STAR")
				current_state = STATES.RESOURCES
				decision_timer.start(GlobalData.AI_DECISION_TIME)
				return
			
				
			if active_builder.can_build("builder"):
				build_ship("builder")
				decision_timer.start(GlobalData.AI_DECISION_TIME)
				return
			else:
				current_state = STATES.RESOURCES
				decision_timer.start(0.1)
				return

func get_rand_neighbour():
	var t = randi() % star.neighbor_stars.size()
	return star.neighbor_stars[t]

func scout_target(target):
	print("SENDING SCOUT TO OTHER STAR")
	var scout = star.get_ship_by_type("scouts", true)
	scout.scout_mission = self
	scout.activate_FTL(target)

func attack_target(target):
	print("ATTACKING TO OTHER STAR")
	star.get_ship_by_type("fighters", true).activate_FTL(target)
	star.get_ship_by_type("fighters", true).activate_FTL(target)
		

func build_ship(type):
	active_builder.build_ship(type, true)

func build_on_planet(type):
	for planet in star.planet_anchor.get_children():
		if planet.can_build(type):
			planet.build(type)
			return

func get_num_scouts():
	var qty = 0
	for ship in star.get_ships():
		if ship.is_in_group("scouts"):
			if ship.is_in_group("enemy"):
				qty += 1
	return qty

func get_num_builders():
	var qty = 0
	for ship in star.get_ships():
		if ship.is_in_group("builders"):
			if ship.is_in_group("enemy"):
				qty += 1
	return qty

func get_num_fighters():
	var qty = 0
	for ship in star.get_ships():
		if ship.is_in_group("fighters"):
			if ship.is_in_group("enemy"):
				qty += 1
	return qty

func get_num_miners():
	var total = 0
	for planet in star.planet_anchor.get_children():
		total += planet.get_num_miners()
	return total

func get_num_solar():
	var total = 0
	for planet in star.planet_anchor.get_children():
		total += planet.get_num_solar()
	return total

func update_builder():
	active_builder = star.get_ship_by_type("builders", true)

func is_builder_available():
	if active_builder == null or not is_instance_valid(active_builder):
		update_builder()
		return
	if (active_builder.current_status == active_builder.STATUSES.BUILDING or 
			active_builder.current_status == active_builder.STATUSES.MOVING):
		return false
	return true

func _on_DecisionTimer_timeout():
	do_action()



func terminate():
	for p in star.planet_anchor.get_children():
		p.remove_buildings()
	star.metal = 100
	star.energy = 100
	print("AI terminated at ", star.star_name)
	queue_free()

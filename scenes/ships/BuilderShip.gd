extends Node2D

onready var selection_sprite = $SelectionSprite
onready var timer = $Timer
onready var progress = $Progress
onready var galaxy = get_tree().get_nodes_in_group("galaxy")[0]
onready var sprite = $Sprite
onready var area2D = $Area2D
onready var warp_tween = $Tween
onready var interstellar_sprite = $InterstellarSprite

var selected = false
var allow_selecting = true
var currently_orbiting = null
var active = false
var build_time = 0
onready var ship_speed = GlobalData.BUILDER_SHIP_SPEED
var destination # target object
var target_vector = null
var currently_building = ""
var build_queue = []
var title = "builder ship"
var interstellar = false
var resting = true
var mission_active = false

var health = GlobalData.BUILDER_HEALTH

enum STATUSES {IDLE, BUILDING, MOVING}
var current_status = STATUSES.IDLE

signal arrived_to_destination

func _ready():
#	position = Vector2(rand_range(-100, 100), rand_range(-100, 100)) # temp
	progress.hide()
	progress.value = 0
	if is_in_group("enemy"):
		modulate = Color.lightcoral
		allow_selecting = false

func _process(delta):
	
	if interstellar and warp_tween.is_active():
		if global_position.distance_to(destination.global_position) < 75:
			warp_tween.stop_all()
			deactivate_FTL()
	
	if selected:
		if Input.is_action_just_pressed("right_mouse"):
			
			if current_status == STATUSES.BUILDING:
				if is_instance_valid(destination) and destination != null:
					if destination.is_in_group("planets"):
						destination.current_status = destination.STATUSES.IDLE
						destination.timer.stop()
					else:
						refund(currently_building)
					progress.hide()
			
			var mouse_pos = get_global_mouse_position()
			if currently_orbiting.global_position.distance_to(mouse_pos) < 200:
				if target_vector != null:
					target_vector.global_position = mouse_pos
					target_vector.show()
				else:
					target_vector = galaxy.create_target_vector_at(mouse_pos)
					target_vector.show()
					
				move_to(target_vector)
			

func _physics_process(delta):
	
	# Check if good distance from star. Move to if not.
	if not interstellar:
		currently_orbiting.energy += delta
		
		
	match current_status:
		STATUSES.IDLE:
			
			if not interstellar and resting:
#				var idle_area = currently_orbiting.global_position + Vector2(50, 0).rotated(currently_orbiting.global_position.angle_to(global_position))
				var dist = global_position.distance_to(currently_orbiting.global_position)
				if dist > 55:
					global_position = global_position.move_toward(currently_orbiting.global_position, ship_speed)
					sprite.look_at(currently_orbiting.global_position)
				elif dist < 45:
					global_position = global_position.move_toward(currently_orbiting.global_position, -ship_speed)
				else:
					resting = false

			
		STATUSES.BUILDING:
			progress.value = ((build_time - timer.time_left) / build_time) * 100.0
			if destination != null and destination.is_in_group("planets"):
				global_position = global_position.move_toward(destination.global_position, 10)
		STATUSES.MOVING:
			global_position = global_position.move_toward(destination.global_position, ship_speed)
			
			if global_position.distance_to(destination.global_position) < 5: 
				emit_signal("arrived_to_destination")
				if target_vector != null:
					target_vector.hide()
#					print(target_vector)
					if destination.is_in_group("planets"):
						current_status = STATUSES.BUILDING
					else:
						current_status = STATUSES.IDLE
						check_for_resting()
					update_readout()
#				destination = null

func build_ship(ship, _enemy = false):
	# Check to make sure resources are good.
	
	build_time = 0
	
	match ship:
		"builder": 
			build_time = GlobalData.BUILDER_SHIP_BUILD_TIME
			currently_orbiting.metal -= GlobalData.BUILDER_SHIP_METAL_COST
			currently_orbiting.energy -= GlobalData.BUILDER_SHIP_ENERGY_COST
		"fighter": 
			build_time = GlobalData.COMBAT_SHIP_BUILD_TIME
			currently_orbiting.metal -= GlobalData.COMBAT_SHIP_METAL_COST
			currently_orbiting.energy -= GlobalData.COMBAT_SHIP_ENERGY_COST
		"scout": 
			build_time = GlobalData.SCOUT_SHIP_BUILD_TIME
			currently_orbiting.metal -= GlobalData.SCOUT_SHIP_METAL_COST
			currently_orbiting.energy -= GlobalData.SCOUT_SHIP_ENERGY_COST
	
	print("Building " + ship)
	current_status = STATUSES.BUILDING
	currently_building = ship
	progress.show()
	timer.start(build_time)
	update_readout()
	
	yield(timer, "timeout")
	if current_status != STATUSES.BUILDING:
		return
	var new_ship
	match ship:
		"builder": new_ship = GlobalData.BUILDER_SHIP.instance()
		"scout": new_ship = GlobalData.SCOUT_SHIP.instance()
		"fighter": new_ship = GlobalData.COMBAT_SHIP.instance()
	new_ship.position = position + Vector2(rand_range(-20, 20), rand_range(-20, 20))
	new_ship.set_orbiting(currently_orbiting)
	if _enemy:
		new_ship.add_to_group("enemy")
	get_parent().add_child(new_ship)
	current_status = STATUSES.IDLE
	update_readout()
	progress.hide()
	check_for_resting()

func summon(planet):
	move_to(planet)

func move_to(target):
	
	# Rotate to and interpolate to position.
	
	destination = target
	current_status = STATUSES.MOVING
	
	sprite.look_at(destination.global_position)
#	sprite.rotate(global_position.angle_to_point(destination.global_position))
	# When arrived
#	emit_signal("arrived_to_destination")
	update_readout()

func can_build(type):
	if currently_orbiting == null: 
		return false
	if current_status != STATUSES.IDLE:
		return false
	match type:
		"builder":
			if currently_orbiting.metal < GlobalData.BUILDER_SHIP_METAL_COST:
				return false
			if currently_orbiting.energy < GlobalData.BUILDER_SHIP_ENERGY_COST:
				return false
			return true
		"scout":
			if currently_orbiting.metal < GlobalData.SCOUT_SHIP_METAL_COST:
				return false
			if currently_orbiting.energy < GlobalData.SCOUT_SHIP_ENERGY_COST:
				return false
			return true
		"fighter":
			if currently_orbiting.metal < GlobalData.COMBAT_SHIP_METAL_COST:
				return false
			if currently_orbiting.energy < GlobalData.COMBAT_SHIP_ENERGY_COST:
				return false
			return true
		

func select():
	selected = true
#	selection_sprite.show()
	if currently_orbiting != null:
		currently_orbiting.select_child(self)
#		currently_orbiting.selected_child = null
	
	if currently_orbiting != null:
		galaxy.canvas_layer.build_menu.activate(self)


func unselect():
	selected = false
	selection_sprite.hide()
	if target_vector != null:
		target_vector.hide()

func update_readout():
	if selected:
		galaxy.canvas_layer.readout.load_details()

func refund(ship):
	match ship:
		"builder":
			currently_orbiting.metal += GlobalData.BUILDER_SHIP_METAL_COST
			currently_orbiting.energy += GlobalData.BUILDER_SHIP_ENERGY_COST
		"scout":
			currently_orbiting.metal += GlobalData.SCOUT_SHIP_METAL_COST
			currently_orbiting.energy += GlobalData.SCOUT_SHIP_ENERGY_COST
		"fighter":
			currently_orbiting.metal += GlobalData.COMBAT_SHIP_METAL_COST
			currently_orbiting.energy += GlobalData.COMBAT_SHIP_ENERGY_COST

func set_orbiting(star):
	currently_orbiting = star

func activate_FTL(star):
	currently_orbiting.hide_neighbour_lines()
	if currently_orbiting.selected_child == self:
		currently_orbiting.unselect_child()
	
	var world_pos = currently_orbiting.global_position
	currently_orbiting.ships.remove_child(self)
	galaxy.add_child(self)
	global_position = world_pos
	currently_orbiting.update_ownership()
	currently_orbiting = null
	interstellar = true
	sprite.hide()
	interstellar_sprite.look_at(star.global_position)
	interstellar_sprite.show()
#	move_to(star)
	destination = star
	
	warp_tween.interpolate_property(self, "global_position", global_position, star.global_position, GlobalData.WARP_SPEED_NORMAL,
		 Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	warp_tween.start()
	print("GOING FTL")

	

func deactivate_FTL():
	print("FINISHED FTL")
	current_status = STATUSES.IDLE
	currently_orbiting = destination
	var world_pos = global_position
	galaxy.remove_child(self)
	currently_orbiting.ships.add_child(self)
	global_position = world_pos
	interstellar = false
	sprite.show()
	interstellar_sprite.hide()
	destination = null
	currently_orbiting.update_ownership()
	
	currently_orbiting.trigger_combat()
	
	if mission_active and currently_orbiting.owned_by == "enemy":
		var new_AI = GlobalData.AI_CONTROLLER.instance()
		new_AI.star = currently_orbiting
		new_AI.active_builder = self
		currently_orbiting.add_child(new_AI)

func _on_Area2D_input_event(viewport, event, shape_idx):
	if interstellar:
		return
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.is_pressed():
		if not selected and allow_selecting:
			get_tree().set_input_as_handled()
			select()

		
func damage(amount):
	health -= amount
	if health <= 0:
		currently_orbiting.trigger_combat()
		queue_free()

func check_for_resting():
	if not resting and current_status == STATUSES.IDLE:
		yield(get_tree().create_timer(3), "timeout")
		resting = true

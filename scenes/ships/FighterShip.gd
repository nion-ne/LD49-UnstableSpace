extends Node2D


onready var selection_sprite = $SelectionSprite
onready var galaxy = get_tree().get_nodes_in_group("galaxy")[0]
onready var sprite = $Sprite
onready var warp_tween = $Tween
onready var interstellar_sprite = $InterstellarSprite
onready var fire_timer = $FireTimer

var selected = false
var currently_orbiting = null
var active = false
var destination = null
var target_vector = null
onready var ship_speed = GlobalData.COMBAT_SHIP_SPEED
var title = "combat ship"
var interstellar = false
var resting = true

#Combat
var health = GlobalData.COMBAT_HEALTH
var target_enemy = null
var fire_cooldown = false

enum STATUSES {IDLE, MOVING, COMBAT}
var current_status = STATUSES.IDLE

signal arrived_to_destination

func _ready():
	if is_in_group("enemy"):
		modulate = Color.lightcoral
	
	check_for_enemies()

func _process(delta):
	
	if interstellar and warp_tween.is_active():
		if global_position.distance_to(destination.global_position) < 75:
			warp_tween.stop_all()
			deactivate_FTL()
	
	
	if selected:
		if Input.is_action_just_pressed("right_mouse"):
			var mouse_pos = get_global_mouse_position()
			if currently_orbiting.global_position.distance_to(mouse_pos) < 250:
				if target_vector != null and is_instance_valid(target_vector):
					target_vector.global_position = mouse_pos
					target_vector.show()
				else:
					target_vector = galaxy.create_target_vector_at(mouse_pos)
					target_vector.show()
				move_to(target_vector)
	


func _physics_process(delta):
	
	
	match current_status:
		STATUSES.IDLE:
			
			pass
			
			
		STATUSES.MOVING:
			global_position = global_position.move_toward(destination.global_position, ship_speed)
			
			if global_position.distance_to(destination.global_position) < 5:
				emit_signal("arrived_to_destination")
				if target_vector != null and is_instance_valid(target_vector):
					target_vector.hide()
	#				print(target_vector)
					current_status = STATUSES.IDLE
					update_readout()
				check_for_enemies()
		STATUSES.COMBAT:
			if target_enemy != null and is_instance_valid(target_enemy):
				if global_position.distance_to(target_enemy.global_position) < 45:
					fire_at_enemy()
				else:
					global_position = global_position.move_toward(target_enemy.global_position, ship_speed)
					sprite.look_at(target_enemy.global_position)
			else:
				check_for_enemies()
			

func move_to(target):
	
	# Rotate to and interpolate to position.
	
	destination = target
	current_status = STATUSES.MOVING
	
	sprite.look_at(destination.global_position)
	
	update_readout()


func set_orbiting(star):
	currently_orbiting = star

func select():
	selected = true
#	selection_sprite.show()
	if currently_orbiting != null and is_instance_valid(currently_orbiting):
		currently_orbiting.select_child(self)
#		currently_orbiting.selected_child = null

func unselect():
	selected = false
	selection_sprite.hide()

func update_readout():
	if selected:
		galaxy.canvas_layer.readout.load_details()


func _on_Area2D_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.is_pressed():
		if not selected and not is_in_group("enemy") and not interstellar:
			select()

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
	check_for_enemies()
	
	currently_orbiting.trigger_combat()
	
func check_for_enemies():
	if not interstellar:
		if is_in_group("enemy"):
			if currently_orbiting.has_player_ship():
#				current_status = STATUSES.COMBAT
				search_and_destroy()
				currently_orbiting.trigger_combat()
		else:
			if currently_orbiting.has_enemy_ship():
#				current_status = STATUSES.COMBAT
				search_and_destroy()
				currently_orbiting.trigger_combat()

func search_and_destroy():
	if is_in_group("enemy"):
		if currently_orbiting.has_player_ship():
			var target = currently_orbiting.get_ship_by_type("fighters", false)
			if target == null:
				target = currently_orbiting.get_ship_by_type("scouts", false)
			if target == null:
				target = currently_orbiting.get_ship_by_type("builders", false)
						
			target_enemy = target
		else:
			current_status = STATUSES.IDLE
	else:
		if currently_orbiting.has_enemy_ship():
			var target = currently_orbiting.get_ship_by_type("fighters", true)
			if target == null:
				target = currently_orbiting.get_ship_by_type("scouts", true)
			if target == null:
				target = currently_orbiting.get_ship_by_type("builders", true)
					
			target_enemy = target
		else:
			current_status = STATUSES.IDLE

func fire_at_enemy():
	if not fire_cooldown:
		var missile = GlobalData.MISSILE.instance()
		missile.target = target_enemy
		if currently_orbiting != null and is_instance_valid(currently_orbiting):
			currently_orbiting.add_child(missile)
		missile.global_position = global_position
		fire_timer.start(GlobalData.COMBAT_COOLDOWN)
		fire_cooldown = true
		yield(fire_timer, "timeout")
		fire_cooldown = false
		
func damage(amount):
	health -= amount
	if health <= 0:
		if currently_orbiting != null and is_instance_valid(currently_orbiting):
			currently_orbiting.trigger_combat()
		queue_free()
		if currently_orbiting != null and is_instance_valid(currently_orbiting):
			currently_orbiting.update_ownership()


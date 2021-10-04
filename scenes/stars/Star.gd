extends Node2D


onready var cam = get_tree().get_nodes_in_group("camera")[0]
onready var big_sprite = $BigSprite
onready var small_sprite = $SmallSprite
onready var selection_indicator = $SelectionIndicator
onready var planet_anchor = $PlanetAnchor
onready var ships = $Ships
onready var galaxy = get_tree().get_nodes_in_group("galaxy")[0]
onready var lines = $Lines 
onready var ownership = $Ownership

const ACTIVATION_ZOOM = Vector2(0.7, 0.7)
const MIN_PLANETS = 1

const PLAYER_COLOUR = Color(0.56, 0.7, 1.0, 0.42)
const ENEMY_COLOUR = Color(1, 0.56, 0.67, 0.6)

const MAX_PLANETS = 5
const NEIGHBOUR_DISTANCE = 500

var active = false
var selected = false
var selected_child = null
var neighbor_stars = []
var neighbor_lines = []

export var num_planets = -1
export var discovered = false
export var owned_by = ""
export var luminosity = 1.0
export var metal = 50
export var energy = 50
export var star_name = "Star"
export var start_with_AI = false

func _ready():
	
	if selected:
		unselect()
	deactivate()
	
	luminosity = rand_range(8.0, 20.0)
	
	if num_planets == -1:
		randomize()
		num_planets = randi() % MAX_PLANETS + MIN_PLANETS
	planet_anchor.generate_planets(num_planets)
	
	if ships.get_child_count() > 0:
		for ship in ships.get_children():
			ship.set_orbiting(self)
	
	
	for star in get_tree().get_nodes_in_group("stars"):
		if star != self:
			if star.global_position.distance_to(global_position) < NEIGHBOUR_DISTANCE:
				neighbor_stars.append(star)
				
				var new_line = Line2D.new()
				new_line.add_point(Vector2(0, 0))
				new_line.add_point(star.position - position)
				new_line.width = 0.5
				new_line.antialiased = true
				new_line.default_color = Color(198, 203, 218, 128)
				neighbor_lines.append(new_line)
				lines.add_child(new_line)
	
	lines.hide()
	
	for s in ships.get_children():
		if not s.is_in_group("enemy"):
			ownership.modulate = PLAYER_COLOUR
			ownership.show()
	
	if start_with_AI:
		var new_AI = GlobalData.AI_CONTROLLER.instance()
		new_AI.star = self
		update_ownership()
		add_start_ship(true)
		add_child(new_AI)
	
	if owned_by == "player":
		ownership.modulate = PLAYER_COLOUR
		ownership.show()

func select_child(target):
	if selected_child != null and is_instance_valid(selected_child):
		selected_child.unselect()
	selected_child = target
	if not target.is_in_group("builders"):
		galaxy.canvas_layer.build_menu.deactivate()
	
	galaxy.canvas_layer.readout.activate(selected_child)

func unselect_child():
	if selected_child != null and is_instance_valid(selected_child):
		selected_child.unselect()
	selected_child = null

func _process(delta):
	if cam.global_position.distance_to(global_position) < 150.0:
		if cam.zoom <= ACTIVATION_ZOOM:
			if not active and discovered:
				if not has_player_ship():
					galaxy.canvas_layer.error_alert.show_error("Must have a ship\nin a system to view it.")
				else:
					activate()
		else:
			if active:
				deactivate()
	else:
		if active:
			deactivate()
	
	if active:
		if selected_child != null:
			if is_instance_valid(selected_child):
				$PlanetSelectionSprite.global_position = selected_child.global_position
				$PlanetSelectionSprite.show()
			else:
				$PlanetSelectionSprite.hide()
		else:
			$PlanetSelectionSprite.hide()
		
	if active and Input.is_action_just_pressed("spawn_enemy"):
		var new_ship = GlobalData.COMBAT_SHIP.instance()
		new_ship.add_to_group("enemy")
		new_ship.set_orbiting(self)
		ships.add_child(new_ship)
		new_ship.global_position = get_global_mouse_position()
	if active and Input.is_action_just_pressed("spawn_fighter"):
		var new_ship = GlobalData.COMBAT_SHIP.instance()
		new_ship.set_orbiting(self)
		ships.add_child(new_ship)
		new_ship.global_position = get_global_mouse_position()
	

func activate():
	active = true
#	anim.play("Active")
	big_sprite.show()
	small_sprite.hide()
	ownership.hide()
	planet_anchor.show()
	ships.show()
	unselect()
	hide_other_stars()
	galaxy.set_active_star(self)
	get_tree().call_group("stars", "hide_neighbour_lines")
#	hide_neighbour_lines()

func deactivate():
	if active:
		show_other_stars()
		galaxy.canvas_layer.readout.deactivate()
		galaxy.canvas_layer.system_details.deactivate()
		galaxy.canvas_layer.build_menu.deactivate()

	active = false
	big_sprite.hide()
	small_sprite.show()
	if owned_by != "":
		ownership.show()
	planet_anchor.hide()
	ships.hide()
	
	if selected_child != null and is_instance_valid(selected_child) and selected_child.is_in_group("ships"):
		galaxy.set_interstellar_child(selected_child)
	unselect_child()
	galaxy.active_star = null

func click():
	if not selected and not active:
		select()
	elif not active:
		if not discovered:
			galaxy.canvas_layer.error_alert.show_error("Must discover a star\nbefore viewing it.")
			return
		if not has_player_ship():
			galaxy.canvas_layer.error_alert.show_error("Must have a ship\nin a system to view it.")
			return
		cam.zoom_to(global_position, ACTIVATION_ZOOM)
		galaxy.canvas_layer.readout.deactivate()

func has_available_builder():
	for ship in ships.get_children():
		if ship.is_in_group("builders") and ship.current_status != ship.STATUSES.BUILDING:
			return true
	return false

func recruit_builder():
	for ship in ships.get_children():
		if ship.is_in_group("builders") and ship.current_status != ship.STATUSES.BUILDING:
			return ship
	return false

func has_player_ship():
	for ship in ships.get_children():
		if not ship.is_in_group("enemy"):
			return true
func has_enemy_ship():
	for ship in ships.get_children():
		if ship.is_in_group("enemy"):
			return true

func select():
	selected = true
	selection_indicator.show()
	galaxy.select_star(self)
#	print("Selected ", name)

func unselect():
	selected = false
	selection_indicator.hide()

func _on_Area2D_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == BUTTON_LEFT:
			click()
		if event.button_index == BUTTON_RIGHT:
			get_tree().set_input_as_handled()
			if galaxy.canvas_layer.interstellar_selection.active:
				galaxy.canvas_layer.interstellar_selection.star_targeted(self)

func hide_other_stars():
	for s in get_tree().get_nodes_in_group("stars"):
		if s.visible and not s == self:
			s.hide()

func show_other_stars():
	for s in get_tree().get_nodes_in_group("stars"):
		if not s.visible and not s == self:
			s.show()

func get_planets():
	return planet_anchor.get_children()

func get_ships():
	return ships.get_children()

func show_neighbour_lines():
	lines.show()

func hide_neighbour_lines():
	lines.hide()

func _unhandled_input(event):
	if event is InputEventMouseButton and active:
		if event.is_pressed():
			if event.button_index == BUTTON_LEFT:
					unselect_child()
					galaxy.canvas_layer.readout.deactivate()
					galaxy.canvas_layer.build_menu.deactivate()

func add_start_ship(enemy = false):
	var start_ship = GlobalData.BUILDER_SHIP.instance()
	start_ship.position = Vector2(50, 50)
	start_ship.currently_orbiting = self
	if enemy:
		start_ship.add_to_group("enemy")
	ships.add_child(start_ship)

func set_ownership(type):
	if owned_by == type:
		return
	
	owned_by = type
	match type:
		"player":
			ownership.modulate = PLAYER_COLOUR
			ownership.show()
			for c in get_children():
				if c.is_in_group("enemy_AI"):
					c.terminate()
			galaxy.canvas_layer.dialogue.add_msg("Secured " + star_name)
		"enemy":
			ownership.modulate = ENEMY_COLOUR
			ownership.show()
			for c in get_children():
				if c.is_in_group("enemy_AI"):
					return
			add_child(GlobalData.AI_CONTROLLER.instance())
		"":
			ownership.hide()

func update_ownership():
	if has_player_ship() and not has_enemy_ship():
		set_ownership("player")
	elif has_enemy_ship() and not has_player_ship():
		set_ownership(("enemy"))
	elif not has_enemy_ship() and not has_player_ship():
		set_ownership("")

func get_ship_by_type(ship, enemy):
		for s in get_ships():
			if s.is_in_group(ship):
				if s.is_in_group("enemy") == enemy:
					return s
		return null

func trigger_combat():
	for s in get_ships():
		if s.is_in_group("fighters"):
			s.current_status = s.STATUSES.COMBAT

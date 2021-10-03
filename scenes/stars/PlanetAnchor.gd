extends Node2D



const ROT_SPEED = 0.001
const MIN_PLANET_RANGE = 30.0
const MAX_PLANET_RANGE = 200.0


func _physics_process(delta):
	rotate(ROT_SPEED)

func generate_planets(num_planets):
	var planet_num = 1
	var positions_of_planets = []
	
	for p in num_planets:
		positions_of_planets.append(place_planet(num_planets))
		
	positions_of_planets.sort()
	
	for p in positions_of_planets:
		var new_planet = get_tree().get_nodes_in_group("galaxy")[0].PLANET.instance()
		
		new_planet.position = positions_of_planets[planet_num - 1]
		# Give planet knowledge about star and other planets to allow proper generation.
		new_planet.setup(planet_num)
		new_planet.parent_star = get_parent()
		
		add_child(new_planet)
		planet_num += 1

# this will be more intelligent based on type
func place_planet(num_planets):
	var step = 2 * PI / num_planets
	var i = 0
	var distance = rand_range(MIN_PLANET_RANGE, MAX_PLANET_RANGE)
	randomize()
	return Vector2(distance, 0).rotated(deg2rad(rand_range(-360, 360)))

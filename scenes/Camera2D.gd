extends Camera2D

onready var tween = $Tween
onready var galaxy = get_parent()
onready var debug_label = $"../CanvasLayer/Label"

var is_panning = false
const key_speed = 10
const zoom_speed = 0.1
const min_zoom = Vector2(0.15, 0.15)
const max_zoom = Vector2(3.0, 3.0)
const default_zoom = Vector2(2.0, 2.0)

var debug_text = ""

func _ready():
	zoom = default_zoom

func _process(delta):
	is_panning = Input.is_action_pressed("middle_mouse")
	
	if is_panning:
		pass
	
	debug_text = "Selected star: "
	if galaxy.selected_star != null and is_instance_valid(galaxy.selected_star):
		debug_text += galaxy.selected_star.name + "\n"
		debug_text += "# planets: " + str(galaxy.selected_star.num_planets) + "\n"
		
		if galaxy.selected_star.selected_child != null and is_instance_valid(galaxy.selected_star):
			debug_text += "\nSelected child: " + galaxy.selected_star.selected_child.name
	
	debug_text += "\nzoom: " + str(zoom) + " \n"
	debug_label.text = debug_text
	
	
func _physics_process(delta):
	keyboard_move()

func keyboard_move():
	if Input.is_action_pressed("w"): position.y -= key_speed
	if Input.is_action_pressed("a"): position.x -= key_speed
	if Input.is_action_pressed("s"): position.y += key_speed
	if Input.is_action_pressed("d"): position.x += key_speed
	

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP:
				if (zoom - zoom * zoom_speed) > min_zoom:
#					zoom -= (zoom * zoom_speed)
					zoom_cam(event.position, -zoom_speed)
				else:
					print("min zoom: ", min_zoom)
			if event.button_index == BUTTON_WHEEL_DOWN:
				if (zoom + zoom * zoom_speed) < max_zoom:
					zoom += (zoom * zoom_speed * 1.3)
#					zoom_cam(event.position, zoom_speed * 1.3)
				else:
					print("max zoom: ", max_zoom)
#			if event.button_index == BUTTON_LEFT:
#				if galaxy.active_star != null and galaxy.active_star.selected_child != null:
#					print("wehewhewhwehweh")
#					galaxy.active_star.unselect_child()
##					galaxy.canvas_layer.readout.deactivate()
	if event is InputEventMouseMotion:
		if is_panning:
			global_position -= event.relative * zoom

func zoom_cam(target_pos, factor):
	
	# Interpolate to target global position
	var viewport_size = get_viewport().size
	var previous_zoom = zoom
	zoom += zoom * factor
	position += ((viewport_size * 0.5) - target_pos) * (zoom - previous_zoom)

func zoom_to(target_pos, target_zoom):
	tween.interpolate_property(self, "zoom", zoom, target_zoom, 1,
			 Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property(self, "position", position, target_pos, 1,
			 Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

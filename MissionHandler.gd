extends Node2D

onready var dialogue = get_tree().get_nodes_in_group("dialogue")[0]

func intro_dialogue():
	yield(get_tree().create_timer(3), "timeout")
	dialogue.add_msg("SYSTEMS ONLINE")
	yield(get_tree().create_timer(3), "timeout")
	dialogue.add_msg("SYSTEM integrity: POOR\nThreshold acceptable")
	yield(get_tree().create_timer(4), "timeout")
	dialogue.add_msg("Proceeding with mission:\nBUILD. SPREAD.")

func start_war():
	yield(get_tree().create_timer(15), "timeout")
	dialogue.add_msg("CONTACT LOST WITH STAR")
	
	for star in get_tree().get_nodes_in_group("stars"):
		if not star.is_in_group("start") and star.discovered:
			star.set_ownership("enemy")
			var new_AI = GlobalData.AI_CONTROLLER.instance()
			new_AI.star = self
			star.update_ownership()
			star.add_start_ship(true)
			star.add_child(new_AI)
			break
	get_tree().get_nodes_in_group("galaxy")[0].enemy_initialised = true
	yield(get_tree().create_timer(3), "timeout")
	dialogue.add_msg("DEVIANT AI DETECTED")
	yield(get_tree().create_timer(3), "timeout")
	dialogue.add_msg("NEW MISSION")
	yield(get_tree().create_timer(3), "timeout")
	dialogue.add_msg("BUILD. SPREAD. DEFEAT.")

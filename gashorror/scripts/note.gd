extends Area3D

func interact(player):
	if player.is_in_group("player"):
		print("Notiz aufgenommen!")
		
		# Update Objectives
		Objectives.set_flag("found_note", true)
		
		# Setze Schritt auf FIND_KEY, wenn noch nicht erreicht
		if Objectives.current_step < Objectives.FIND_KEY:
			Objectives.set_step(Objectives.FIND_KEY)
		
		# Notiz aus der Szene entfernen, nachdem sie eingesammelt wurde
		queue_free()

extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world._profile_token = Crypto.new().generate_random_bytes(32).hex_encode()
	world._connect_client("127.0.0.1",28996,"GearNetTest")
	var equipped := false
	var upgraded := false
	for tick in range(1800):
		await process_frame
		if world._progress.is_empty() or not is_instance_valid(world._local_player):
			continue
		var state: Dictionary = world._progress
		var items: Array = state.get("inventory",[])
		if items.is_empty():
			continue
		if not equipped:
			world._equip_inventory.rpc_id(1,"stage846_weapon")
			equipped = true
			continue
		if state.get("equipped_slots",{}).get("weapon","") != "stage846_weapon":
			continue
		if not upgraded:
			world._upgrade_item.rpc_id(1,"stage846_weapon")
			upgraded = true
			continue
		if int(state.get("gold",0)) == 100 and int(state.get("gear_score",0)) == 330 and int(items[0].get("upgrade_level",0)) == 1:
			print("STAGE846_CLIENT=PASS real_enet_rpc_equip_upgrade_state gold=100 gs=330")
			quit(0)
			return
	push_error("STAGE846 client timed out equipped="+str(equipped)+" upgraded="+str(upgraded)+" progress="+str(world._progress))
	quit(1)

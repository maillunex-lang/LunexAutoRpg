extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://game/network/online_world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var token := Crypto.new().generate_random_bytes(32).hex_encode()
	world._profile_token = token
	world._connect_client("127.0.0.1",28997,"ReconnectGear")
	var equipped := false
	var upgraded := false
	var reconnecting := false
	for tick in range(3500):
		await process_frame
		if not reconnecting and not world._progress.is_empty() and is_instance_valid(world._local_player):
			var state: Dictionary = world._progress
			if state.get("inventory",[]).is_empty():
				continue
			if not equipped:
				world._equip_inventory.rpc_id(1,"stage847_weapon")
				equipped = true
				continue
			if state.get("equipped_slots",{}).get("weapon","") != "stage847_weapon":
				continue
			if not upgraded:
				world._upgrade_item.rpc_id(1,"stage847_weapon")
				upgraded = true
				continue
			if int(state.get("gold",0)) == 100 and int(state.get("gear_score",0)) == 330:
				world._close_client("test reconnect")
				reconnecting = true
				for delay in range(30):
					await process_frame
				world._profile_token = token
				world._connect_client("127.0.0.1",28997,"ReconnectGear")
				continue
		if reconnecting and is_instance_valid(world._local_player) and not world._progress.is_empty():
			var state: Dictionary = world._progress
			var items: Array = state.get("inventory",[])
			if items.size() == 1 and int(state.get("gold",0)) == 100 and int(state.get("gear_score",0)) == 330 and state.get("equipped_slots",{}).get("weapon","") == "stage847_weapon" and int(items[0].get("upgrade_level",0)) == 1:
				print("STAGE847_CLIENT=PASS same_token_reconnect gear_score=330 gold=100 upgrade=1")
				quit(0)
				return
	push_error("STAGE847 client timeout reconnecting="+str(reconnecting)+" progress="+str(world._progress))
	quit(1)

extends "res://tests/stage06_smoke.gd"
## Run the integrated prepare/reload scenario and observe animation replication.

var _clients: Array[Node] = []

func _client(node_name: String) -> Node:
	var client := super._client(node_name)
	_clients.append(client)
	return client

func _hit(client: Node, health_after: int) -> bool:
	var observer := _clients[1] if client == _clients[0] else _clients[0]
	var remote := observer.players.get_node_or_null(str(client.multiplayer.get_unique_id())) as LunexNetworkPlayer
	if remote == null:
		return await super._hit(client, health_after)
	var previous_attack := remote.attack_sequence
	client.combat.selected = true
	client.combat.auto_requested.emit(true)
	if not await _expect("a remote client sees the running animation", func() -> bool:
		return remote.hero_visual.clips.current_animation == remote.hero_visual.run_clip
	):
		return false
	if not await _expect("a remote client sees the confirmed attack animation", func() -> bool:
		return remote.attack_sequence > previous_attack and remote.hero_visual.clips.current_animation == remote.hero_visual.attack_clip
	):
		return false
	client.combat.auto_requested.emit(false)
	return await _expect("both clients see target health after the hit", func() -> bool:
		return client.enemy.health == health_after and observer.enemy.health == health_after
	)

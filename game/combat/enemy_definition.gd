class_name LunexEnemyDefinition
extends Resource

# Stable instance ID and spawn point ID are not quest target IDs.
# All gameplay balancing parameters are editable through the native Godot inspector.
@export var enemy_instance_id: String = ""
@export var spawn_point_id: String = ""
@export var target_id: String = ""
@export var target_name: String = ""
@export_range(0, 4, 1) var zone_id: int = 0
@export_range(1, 20000, 1) var max_health: int = 60
@export_range(0.5, 600.0, 0.5) var respawn_delay: float = 4.0
@export_range(0.0, 30.0, 0.5) var aggro_radius: float = 6.0
@export_range(0.0, 50.0, 0.5) var leash_radius: float = 14.0
@export_range(0.1, 8.0, 0.1) var patrol_speed: float = 1.6
@export_range(0.1, 8.0, 0.1) var chase_speed: float = 2.6
@export_range(0.1, 5.0, 0.1) var damage_threat_factor: float = 1.0
@export_range(0.1, 5.0, 0.1) var healing_threat_factor: float = 0.7

func is_valid_definition() -> bool:
	return not enemy_instance_id.strip_edges().is_empty() and not spawn_point_id.strip_edges().is_empty() and not target_id.strip_edges().is_empty() and not target_name.strip_edges().is_empty() and max_health > 0 and respawn_delay > 0.0 and leash_radius >= aggro_radius and patrol_speed > 0.0 and chase_speed > 0.0

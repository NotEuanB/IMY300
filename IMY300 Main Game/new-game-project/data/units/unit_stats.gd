class_name UnitStats
extends Resource

@export var name: String
@export var unit_scene: PackedScene

@export_category("Data")
@export var gold_cost := 1
@export var attack := 2
@export var health := 1
@export var pool_count := 5
@export var tier: int = 1

@export_category("Visuals")
@export var skin: Texture2D
@export var description: String = ""

@export var buff_used := false

@export var base_attack: int = 0
@export var base_health: int = 0

func _to_string() -> String:
	return name

func initialize_base_stats():
	if base_attack == 0:
		base_attack = attack
	if base_health == 0:
		base_health = health

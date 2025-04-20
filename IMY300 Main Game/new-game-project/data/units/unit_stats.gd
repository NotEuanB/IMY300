class_name UnitStats
extends Resource

@export var name: String

@export_category("Data")
@export var gold_cost := 1
@export var attack := 2
@export var health := 1
@export var pool_count := 5

@export_category("Visuals")
@export var skin: Texture2D
@export var portrait: Texture2D
@export var description: String = ""

func _to_string() -> String:
	return name

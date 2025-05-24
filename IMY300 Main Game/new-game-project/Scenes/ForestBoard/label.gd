extends Label

@export var player_stats: PlayerStats

func _ready() -> void:
	$".".text = str(player_stats.health)

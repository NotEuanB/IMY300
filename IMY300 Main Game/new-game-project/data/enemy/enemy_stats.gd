class_name EnemyStats
extends Resource

@export_category("Visuals")
@export var skin: Texture2D

@export_category("Boss Properties")
@export var is_boss: bool = false
@export var boss_name: String = ""
@export var boss_effect_type: BossEffectType = BossEffectType.NONE

@export_category("Units")
@export var units: Array[PackedScene] = []
@export var unit_stats: Array[UnitStats] = []

enum BossEffectType {
	NONE,
	BLAZING_AURA,     # Ashfang - All enemies gain +1 attack and retaliate
	DEATH_TAX,        # Bone Collector - Boss gains +1/+1 when any unit dies
	CHAOTIC_WINDS,    # Mistral - Shuffle unit positions each round
	FROST_ARMOR,      # Example: All enemies gain +1 health and armor
	SHADOW_CURSE      # Example: Player units lose 1 attack
}

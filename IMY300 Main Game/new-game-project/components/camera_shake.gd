class_name CameraShake
extends Camera2D

# Simple camera shake using tweened random position offsets.

var _orig_pos: Vector2
var _tween: Tween

func _ready() -> void:
    _orig_pos = position

func shake(intensity: float = 8.0, duration: float = 0.15, steps: int = 6) -> void:
    if steps <= 0:
        return
    if _tween and _tween.is_running():
        _tween.kill()
    position = _orig_pos

    var rng := RandomNumberGenerator.new()
    rng.randomize()

    _tween = create_tween()
    _tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    var dt := duration / float(steps)
    for i in range(steps):
        var falloff := (steps - i) / float(steps)
        var target := _orig_pos + Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * intensity * falloff
        _tween.tween_property(self, "position", target, dt)
    _tween.tween_property(self, "position", _orig_pos, dt)

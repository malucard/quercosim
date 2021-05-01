extends KinematicBody

var colors = [
	Color.green,
	Color.aqua,
	Color.brown,
	Color.white,
	Color.yellow,
	Color.pink,
	Color.purple,
	Color.blue
]

func _ready():
	$amogus/Armature/Skeleton/Cube.material_override = $amogus/Armature/Skeleton/Cube.mesh.surface_get_material(0).duplicate()
	$amogus/Armature/Skeleton/Cube.material_override.albedo_color = colors[int(name.substr(6, 1)) - 2]

const SPEED = 12
var gravity = 0
var walking = true
var rot = 0.0

func _physics_process(delta):
	if randf() < 0.25 * delta:
		walking = not walking
	rot = clamp(rot + (randf() - 0.5), -PI, PI)
	var dir = global_transform.basis.x if walking else Vector3()
	dir.y = 0
	dir = dir.normalized()
	if dir != Vector3():
		$amogus/AnimationPlayer.play("walk")
	else:
		$amogus/AnimationPlayer.stop()
	move_and_slide_with_snap(dir * SPEED + Vector3(0, gravity, 0), Vector3(0, -0.2, 0), Vector3.UP, true)
	if is_on_floor():
		gravity = 0
	else:
		gravity -= 15 * delta
	rotate_y(rot * delta)

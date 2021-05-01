extends Spatial

const SPEED = 12
var gravity = 0
var title = true
var barbie = false

func _ready():
	$AudioStreamPlayer/TextureRect.visible = true
	$amogus/amogus.transform.basis.z = Vector3(0, 0, 1)
	$amogus/amogus.transform.basis.x = Vector3(-1, 0, 0)
	var target_position = $amogus/Camera.global_transform.origin + $amogus/amogus.global_transform.basis.z.normalized()
	var new_transform = $amogus/Camera.global_transform.looking_at(target_position, Vector3.UP)
	$amogus/Camera.global_transform = new_transform

func _process(_delta):
	if title or barbie:
		if Input.is_action_just_pressed("amogus_confirm"):
			_on_TextureRect_pressed()
		return
	PhysicsServer.set_active(true)
	$amogus/Camera/Camera.look_at($amogus/amogus.global_transform.origin, Vector3.UP)
	$amogus_ship/AnimationPlayer.get_animation("SphereAction002").track_set_path(0, @"Sphere")
	$amogus_ship/AnimationPlayer.play("SphereAction002")
	$AnimationPlayer.play("spoopy")

var mobile_origin = null
var mobile_dir = Vector2()

func _physics_process(delta):
	if barbie or title:
		return
	var rot = mobile_dir != Vector2()
	var forward = -$amogus/Camera/Camera.global_transform.basis.z
	var right = $amogus/Camera/Camera.global_transform.basis.x
	var dir = Vector3(mobile_dir.x, 0, -mobile_dir.y)
	if Input.is_action_pressed("amogus_left"):
		dir.x -= 1
		rot = true
	if Input.is_action_pressed("amogus_right"):
		dir.x += 1
		rot = true
	if Input.is_action_pressed("amogus_forward"):
		dir.z += 1
		rot = true
	if Input.is_action_pressed("amogus_back"):
		dir.z -= 1
	dir = dir.normalized()
	dir = (forward * dir.z + right * dir.x)
	dir.y = 0
	dir = dir.normalized()
	if dir != Vector3():
		$amogus/amogus.transform.basis.x = dir.cross(Vector3.UP)
		$amogus/amogus.transform.basis.z = dir
		$amogus/amogus/AnimationPlayer.play("walk")
	else:
		$amogus/amogus/AnimationPlayer.stop()
	$amogus.move_and_slide_with_snap(dir * SPEED + Vector3(0, gravity, 0), Vector3(0, -0.2, 0), Vector3.UP, true)
	if $amogus.is_on_floor():
		gravity = 0
	else:
		gravity -= 15 * delta
	var rel_dir = global_transform.origin + dir
	if rot:
		var target_position = $amogus/Camera.global_transform.origin + $amogus/amogus.global_transform.basis.z.normalized()
		var new_transform = $amogus/Camera.global_transform.looking_at(target_position, Vector3.UP)
		$amogus/Camera.global_transform = $amogus/Camera.global_transform.interpolate_with(new_transform, 4 * delta)

func _on_Area_body_entered(body):
	if body == $amogus:
		barbie = true
		$AnimationPlayer2.play("special_barbie_ending")

func _on_TextureRect_pressed():
	title = false
	$AudioStreamPlayer/TextureRect.visible = false

func _input(event):
	if barbie or title:
		return
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			mobile_origin = event.position
		else:
			mobile_origin = null
			mobile_dir = Vector2()
	elif event is InputEventMouseMotion and mobile_origin:
		var dir = (event.position - mobile_origin).normalized()
		mobile_dir.x = sign(dir.x) if abs(dir.x) >= 0.5 else 0.0
		mobile_dir.y = sign(dir.y) if abs(dir.y) >= 0.5 else 0.0

func stop_it_already_aaaaaaaaaaaaa():
	get_tree().paused = false
	$"../../".queue_free()

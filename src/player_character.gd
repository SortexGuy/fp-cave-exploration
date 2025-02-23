extends CharacterBody3D
class_name Player

enum PLAYER_STATES {
	GROUNDED,
	MIDAIR,
	CROUCHING,
	CLIMBING,
}

var player_state: PLAYER_STATES = PLAYER_STATES.GROUNDED
var previous_state: PLAYER_STATES

const MASS = 4.0
const JUMP_VELOCITY = 3.0 * MASS

@export var inventory: Inventory

@export_range(0.0, 10.0, 0.1) var WALK_SPEED = 5.0
@onready var RUN_SPEED = WALK_SPEED * 2.2
@onready var SLOW_SPEED = WALK_SPEED * 0.7

@export_range(0.0001, 1.0, 0.0001)
var mouse_sens: float = .01

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head_pivot: Node3D = %HeadPivot
@onready var main_cam: Camera3D = %MainCamera
@onready var flashlight: SpotLight3D = %Flashlight
@onready var wall_climb_cast: ShapeCast3D = %WallClimbCast
@onready var wall_grab_cast: ShapeCast3D = %WallGrabCast
@onready var pickaxe_cast: ShapeCast3D = %PickaxeCast
@onready var interaction_cast: ShapeCast3D = %InteractionCast
@onready var anti_clip_cast: ShapeCast3D = %AntiClipCast

@onready var high_body_collision: CollisionShape3D = %HighBodyCollision
@onready var high_body: Area3D = %HighBody
@onready var high_head: Marker3D = %HighHead
@onready var low_head: Marker3D = %LowHead
@onready var hurtboxes: Node3D = %HurtBoxes

@onready var gas_timer: Timer = %GasTimer
@onready var pickaxe_timer: Timer = %PickaxeTimer
@onready var sound_fx: PlayerSoundFXController = $SoundFX

var run_toggle: bool = false
var wall_direction: Vector3 = Vector3.ZERO
var prev_dir_zero: bool = false

func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_DISABLED
	ModManager.mod_added.connect(mods_added)
	ModManager.mod_removed.connect(mods_removed)
	GameManager._set_p_inv(inventory)
	
	for hurtbox in hurtboxes.get_children() as Array[HurtBox]:
		hurtbox.player = self

func _physics_process(delta: float) -> void:
	match player_state:
		PLAYER_STATES.GROUNDED:
			_grounded_state(delta)
		PLAYER_STATES.MIDAIR:
			_midair_state(delta)
		PLAYER_STATES.CROUCHING:
			_crouching_state(delta)
		PLAYER_STATES.CLIMBING:
			_climbing_state(delta)
	
	_handle_interaccion(delta)
	if player_state != PLAYER_STATES.CLIMBING:
		_movement_process(delta)
		_handle_pickaxe(delta)
	else:
		_wall_movement(delta)

func _grounded_state(delta: float) -> void:
	velocity.y = 0.0
	
	if not is_on_floor():
		previous_state = player_state
		player_state = PLAYER_STATES.MIDAIR
	# Handle jump.
	elif Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY
		
		previous_state = player_state
		player_state = PLAYER_STATES.MIDAIR
	elif Input.is_action_just_pressed("crouch_toggle"):
		high_body.monitorable = false
		high_body_collision.disabled = true
		head_pivot.global_position.y = low_head.global_position.y
		
		sound_fx.run_state_change.emit(false)
		previous_state = player_state
		player_state = PLAYER_STATES.CROUCHING
	elif Input.is_action_just_pressed("grab_wall") and wall_climb_cast.enabled:
		wall_climb_cast.force_shapecast_update()
		if wall_climb_cast.is_colliding():
			var res = wall_climb_cast.collision_result.front()
			
			wall_direction = -res.normal
			var grab_xform: = wall_grab_cast.global_transform
			wall_grab_cast.global_transform.basis = grab_xform.basis.looking_at(
				grab_xform.origin + wall_direction)
			velocity = Vector3.ZERO
		
			previous_state = player_state
			player_state = PLAYER_STATES.CLIMBING

func _midair_state(delta: float) -> void:
	# Add the gravity.
	velocity.y -= gravity * MASS * delta
	if is_on_floor():
		previous_state = player_state
		player_state = PLAYER_STATES.GROUNDED

func _crouching_state(delta: float) -> void:
	if not is_on_floor():
		previous_state = player_state
		player_state = PLAYER_STATES.MIDAIR
	elif Input.is_action_just_pressed("crouch_toggle") and \
		not anti_clip_cast.is_colliding():
		sound_fx.run_state_change.emit(run_toggle)
		previous_state = player_state
		player_state = PLAYER_STATES.GROUNDED
	
	if player_state != PLAYER_STATES.CROUCHING:
		high_body.monitorable = true
		high_body_collision.disabled = false
		head_pivot.global_position.y = high_head.global_position.y

func _climbing_state(delta: float) -> void:
	if (head_pivot.transform.basis * Vector3.FORWARD)\
		.normalized().dot(wall_direction) < -0.4 or \
		not Input.is_action_pressed("grab_wall") or \
		not is_on_wall():
		
		previous_state = player_state
		player_state = PLAYER_STATES.MIDAIR
		

func _movement_process(delta: float) -> void:
	# Toggle run.
	if Input.is_action_just_pressed("run_toggle"):
		sound_fx.run_state_change.emit(run_toggle)
		run_toggle = !run_toggle
	
	var speed = WALK_SPEED if !run_toggle else RUN_SPEED
	if player_state == PLAYER_STATES.CROUCHING:
		speed = SLOW_SPEED
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (head_pivot.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, WALK_SPEED)
	
	move_and_slide()
	
	if prev_dir_zero and not input_dir.is_zero_approx():
		sound_fx.sfx_animations.play("FootSteps")
	elif not prev_dir_zero and input_dir.is_zero_approx():
		sound_fx.sfx_animations.stop()
	prev_dir_zero = input_dir.is_zero_approx()

func _handle_pickaxe(delta: float) -> void:
	if Input.is_action_pressed("use_pickaxe") and pickaxe_timer.is_stopped():
		pickaxe_cast.force_shapecast_update()
		if not pickaxe_cast.is_colliding(): return
		pickaxe_timer.start()
		sound_fx.pickaxe_play()
		var res := pickaxe_cast.collision_result.front() as Dictionary
		if res.collider is Area3D:
			GameManager.mineral_ending.emit()
			self.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			var collider := res.collider as DestructibleStone
			collider.destroy()

func _handle_interaccion(delta: float) -> void:
	if not Input.is_action_just_pressed("interaction_cast"): return
	interaction_cast.force_shapecast_update()
	if not interaction_cast.is_colliding(): return
	var res := interaction_cast.collision_result.front() as Dictionary
	
	if res.collider is not ObjectItem:
		var collider := res.collider as Area3D
		if collider.collision_layer & 256 and \
		inventory.has_modifier(ModManager.Modifiers.Harness):
			sound_fx.broken_harness.play()
			GameManager.hole_ending.emit()
		elif collider.collision_layer & 512 and \
		inventory.has_modifier(ModManager.Modifiers.Camera):
			sound_fx.camera_flash.play()
			GameManager.camera_ending.emit()
		self.process_mode = Node.PROCESS_MODE_DISABLED
		return
	
	var collider := res.collider as ObjectItem
	
	var item: InventoryItem = collider.item
	if inventory.has_modifier(item.modifier):
		collider.selected = false
		inventory.remove_item(item)
		return
	elif inventory.is_full():
		# Mostrar que no puedes hacer nada
		return
	
	collider.selected = true
	inventory.add_item(item)

func _wall_movement(delta: float) -> void:
	wall_grab_cast.force_shapecast_update()
	var wall_basis: Vector3 = wall_grab_cast.global_transform.basis * Vector3.FORWARD
	var xform: Transform3D
	if wall_grab_cast.is_colliding():
		var res: Dictionary = wall_grab_cast.collision_result.front()
		var point: Vector3 = res.point - (res.normal * 0.5)
		xform = wall_grab_cast.global_transform.looking_at(point)
		wall_grab_cast.global_transform = xform
	else:
		xform = wall_climb_cast.global_transform
	
	var speed = SLOW_SPEED
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (xform.basis * Vector3(input_dir.x, -input_dir.y, -0.75)).normalized()
	if input_dir:
		velocity = direction * speed
		#velocity.x = direction.x * speed
		#velocity.y = direction.y * speed
	else:
		velocity = Vector3.ZERO
		#velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		#velocity.y = move_toward(velocity.y, 0, WALK_SPEED)
	
	move_and_slide()
	
	if prev_dir_zero and not input_dir.is_zero_approx():
		sound_fx.sfx_animations.play("Piolets")
	elif not prev_dir_zero and input_dir.is_zero_approx():
		sound_fx.sfx_animations.stop()
	prev_dir_zero = input_dir.is_zero_approx()

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_ESCAPE:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				else:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if event is InputEventMouseMotion and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		var rel_vec = event.relative.x * mouse_sens
		head_pivot.rotate_y(-deg_to_rad(rel_vec))
		rel_vec = event.relative.y * mouse_sens
		main_cam.rotate_x(-deg_to_rad(rel_vec))

func mods_added(mod: ModManager.Modifiers) -> void:
	match mod:
		ModManager.Modifiers.FlashlightHelmet:
			sound_fx.flashlight.play()
			flashlight.show()
		ModManager.Modifiers.GasMask:
			sound_fx.gas_mask.play()
		ModManager.Modifiers.Piolet:
			wall_climb_cast.enabled = true
		ModManager.Modifiers.Pickaxe:
			pickaxe_cast.enabled = true

func mods_removed(mod: ModManager.Modifiers) -> void:
	match mod:
		ModManager.Modifiers.FlashlightHelmet:
			sound_fx.flashlight.play()
			flashlight.hide()
		ModManager.Modifiers.GasMask:
			sound_fx.gas_mask.stop()
		ModManager.Modifiers.Piolet:
			wall_climb_cast.enabled = false
		ModManager.Modifiers.Pickaxe:
			pickaxe_cast.enabled = false

func _on_hurt_boxes_take_damage() -> void:
	
	get_tree().reload_current_scene()

func _on_hurtboxes_gas_entered() -> void:
	if inventory.has_modifier(ModManager.Modifiers.GasMask): return
	sound_fx.coughs.play()
	gas_timer.start()

func _on_hurtboxes_gas_exited() -> void:
	sound_fx.coughs.stop()
	gas_timer.stop()

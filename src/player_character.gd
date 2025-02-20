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
@onready var RUN_SPEED = WALK_SPEED * 1.9
@onready var SLOW_SPEED = WALK_SPEED * 0.7

@export_range(0.00001, 0.1, 0.00001)
var mouse_sens: float = .001

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head_pivot: Node3D = %HeadPivot
@onready var main_cam: Camera3D = %MainCamera
@onready var flashlight: SpotLight3D = %Flashlight
@onready var wall_climb_cast: ShapeCast3D = %WallClimbCast

@onready var high_body_collision: CollisionShape3D = %HighBodyCollision
@onready var high_body: Area3D = %HighBody
@onready var high_head: Marker3D = %HighHead
@onready var low_head: Marker3D = %LowHead
@onready var hud: HeadsUpDisplay = %HUD
@onready var hurtboxes: Node3D = %HurtBoxes

# Wall Grab Variable
var wall_direction: Vector3 = Vector3.ZERO

var wall_grab_toggle: bool = false
var run_toggle: bool = false

func _ready() -> void:
	ModManager.mod_added.connect(mods_added)
	ModManager.mod_removed.connect(mods_removed)
	
	for hurtbox in hurtboxes.get_children() as Array[HurtBox]:
		hurtbox.player = self
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
	
	handle_modifiers(delta)
	if player_state != PLAYER_STATES.CLIMBING:
		_movement_process(delta)
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
		
		previous_state = player_state
		player_state = PLAYER_STATES.CROUCHING
	elif Input.is_action_just_pressed("grab_wall") and wall_grab_toggle:
		wall_climb_cast.force_shapecast_update()
		if wall_climb_cast.is_colliding():
			var res = wall_climb_cast.collision_result.front()
			wall_direction = -res.normal
		
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
	elif Input.is_action_just_pressed("crouch_toggle"):
		previous_state = player_state
		player_state = PLAYER_STATES.GROUNDED
	
	if player_state != PLAYER_STATES.CROUCHING:
		high_body.monitorable = true
		high_body_collision.disabled = false
		head_pivot.global_position.y = high_head.global_position.y

func _climbing_state(delta: float) -> void:
	if (head_pivot.transform.basis * Vector3.FORWARD)\
		.normalized().dot(wall_direction) < -0.4 or \
		not Input.is_action_pressed("grab_wall"):
		
		previous_state = player_state
		player_state = PLAYER_STATES.MIDAIR

func _movement_process(delta: float) -> void:
	# Toggle run.
	if Input.is_action_just_pressed("run_toggle"):
		run_toggle = !run_toggle
	
	var speed = WALK_SPEED if !run_toggle else RUN_SPEED
	if player_state == PLAYER_STATES.CROUCHING:
		speed = SLOW_SPEED
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (head_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, WALK_SPEED)
	
	move_and_slide()

func _wall_movement(delta: float) -> void:
	var speed = WALK_SPEED * 0.7
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var xform: Transform3D = head_pivot.transform.looking_at(transform.origin + wall_direction)
	var direction = (xform.basis * Vector3(input_dir.x, -input_dir.y, 0)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.y = direction.y * speed
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		velocity.y = move_toward(velocity.y, 0, WALK_SPEED)
	
	move_and_slide()

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

func handle_modifiers(delta: float) -> void:
	var i: int = -1
	for action in ["mod_1","mod_2","mod_3","mod_4","mod_5","mod_6"]:
		i += 1
		if Input.is_action_just_pressed(action):
			var item: InventoryItem = InventoryItem.new()
			var mods := ModManager.Modifiers.values()
			item.modifier = mods[i]
			if inventory.has_modifier(item.modifier):
				inventory.remove_item(item)
			else:
				inventory.add_item(item)

func mods_added(mod: ModManager.Modifiers) -> void:
	match mod:
		ModManager.Modifiers.FlashlightHelmet:
			flashlight.show()
		ModManager.Modifiers.Piolet:
			wall_grab_toggle = true

func mods_removed(mod: ModManager.Modifiers) -> void:
	match mod:
		ModManager.Modifiers.FlashlightHelmet:
			flashlight.hide()
		ModManager.Modifiers.Piolet:
			wall_grab_toggle = false

func _on_hurt_boxes_take_damage() -> void:
	get_tree().reload_current_scene()

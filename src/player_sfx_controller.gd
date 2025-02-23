extends Node
class_name PlayerSoundFXController

signal run_state_change(running: bool)

@onready var foot_steps: AudioStreamPlayer = %FootSteps
@onready var pickaxe: AudioStreamPlayer = %Pickaxe
@onready var sfx_animations: AnimationPlayer = $SFXAnimations
@onready var coughs: AudioStreamPlayer = %Coughs
@onready var flashlight: AudioStreamPlayer = %Flashlight
@onready var gas_mask: AudioStreamPlayer = %GasMask
@onready var camera_flash: AudioStreamPlayer = %CameraFlash
@onready var broken_harness: AudioStreamPlayer = %BrokenHarness

func _ready() -> void:
	run_state_change.connect(_on_run_state_change)

func _on_run_state_change(running: bool) -> void:
	if running:
		foot_steps.pitch_scale = 3.0
		return
	foot_steps.pitch_scale = 2.0

func pickaxe_play() -> void:
	pickaxe.play()

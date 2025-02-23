extends EndScreen

@onready var color_rect: ColorRect = %ColorRect

func _ready() -> void:
	color_rect.color.a = 0.0
	GameManager.camera_ending.connect(begin_sequence)

func begin_sequence() -> void:
	color_rect.color.a = 1.0
	super.begin_sequence()

extends CanvasLayer
class_name HeadsUpDisplay

@onready var item_tex_rect_1: TextureRect = %ItemTextureRect1
@onready var item_tex_rect_2: TextureRect = %ItemTextureRect2
@onready var item_tex_rect_3: TextureRect = %ItemTextureRect3

func _ready() -> void:
	var arr: Array[TextureRect] = [item_tex_rect_1, item_tex_rect_2, item_tex_rect_3]
	GameManager.hud_item_tex_rects = arr

func tween_hide() -> void:
	self.hide()

func tween_show() -> void:
	self.show()

extends CanvasLayer

@onready var rect = $ScreenFader

func _ready():
	# 初始状态设为透明
	rect.color.a = 0

func change_scene(path: String, delay: float = 0.5):
	var tween = create_tween()
	# 1. 变黑
	tween.tween_property(rect, "color:a", 1.0, delay)
	# 2. 换关
	tween.tween_callback(func(): get_tree().change_scene_to_file(path))
	# 3. 变透明
	tween.tween_property(rect, "color:a", 0.0, delay)

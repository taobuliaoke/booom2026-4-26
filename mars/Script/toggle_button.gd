extends TextureButton

@onready var reasoning_page = $"../ReasoningPage"

#预加载
var normal_img = preload("res://art/UI/ToggleButton.png")
var pressed_img = preload("res://art/UI/ToggleButton_open.png")

func _ready() -> void:
	# 确保已经指定了 normal texture
	if texture_normal:
		texture_click_mask = create_bitmap_from_texture(texture_normal)

func create_bitmap_from_texture(tex: Texture2D) -> BitMap:
	var bitmap = BitMap.new()
	# 根据纹理尺寸创建一个空的位图
	bitmap.create(tex.get_size())
	
	# 获取 Image 数据以便访问像素
	var img = tex.get_image()
	
	# 自动根据 Alpha 通道创建遮罩
	# 参数 0.5 是 alpha 阈值（0.0 到 1.0）
	# 只有 alpha 大于 0.5 的像素才会被视为“可点击”
	bitmap.create_from_image_alpha(img, 0.5)
	
	return bitmap
	
	
func _pressed():
	# 切换显示或隐藏（取反逻辑）
	reasoning_page.visible = !reasoning_page.visible
	
	# 细节处理：打开推理页时，可以改变按钮文字[[[]]
	if reasoning_page.visible:
		#打开时候
		texture_normal = pressed_img
		print('return')
	else:
		#关闭时候
		texture_normal = normal_img
		print('check')

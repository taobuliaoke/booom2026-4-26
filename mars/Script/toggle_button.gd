extends TextureButton

@onready var reasoning_page = $"../../ReasoningPage"
@onready var environment = $"../../Environment" #拿来吧你

#预加载
var normal_img = preload("res://art/UI/ToggleButton.png")
var pressed_img = preload("res://art/UI/ToggleButton_open.png")
#记录Environment的初始位置
var env_original_pos:Vector2

func _ready() -> void:
	reasoning_page.visible = false
	# 确保已经指定了 normal texture
	if texture_normal:
		texture_click_mask = create_bitmap_from_texture(texture_normal)
	#记录初始位置方便日后还原
	if environment:
		env_original_pos = environment.position
		

func _pressed():
	# 切换显示或隐藏（取反逻辑）
	reasoning_page.visible = !reasoning_page.visible
	#执行场景平移补间动画
	run_env_animation(reasoning_page.visible)
	
	# 细节处理：打开推理页时，可以改变按钮文字[[[]]
	if reasoning_page.visible:
		#打开时候
		texture_normal = pressed_img
		print('return')
	else:
		#关闭时候
		texture_normal = normal_img
		print('check')


#重生之，动画，做
func run_env_animation(is_opening:bool):
	
	if not environment:return
	
	#创建tween
	var tween = create_tween()
	
	#设置弹性动画参数
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	if  is_opening:
		#推理页打开时，场景从下往上移出镜头（减去屏幕高度）
		var target_pos = env_original_pos + Vector2(0,-1000)
		tween.tween_property(environment,'position',target_pos,1.5)
	else:
		
		#推理页关闭，场景归位
		tween.tween_property(environment,'position',env_original_pos,1.5)
		
		
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

# 挂在 Slide 根节点上的脚本
extends Node2D

# 为每个图层设置不同的“敏感度”
# 数值越小越远，数值越大越近
@export var layers_config = {
	"static": 0,
	"distant": 0.005,
	"medium": 0.01,
	"close": 0.02
}

var base_positions = {} # 记录各层级的初始位置

func _ready():
	# 记录初始位置，防止位移后回不来
	for layer_name in layers_config.keys():
		var layer_node = get_node_or_null(layer_name)
		if layer_node:
			base_positions[layer_name] = layer_node.position

func _process(_delta):
	# 获取鼠标相对于窗口中心的偏移量
	var viewport_size = get_viewport_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	
	# 计算偏移向量（以中心为 0,0）
	var offset = mouse_pos - (viewport_size / 2.0)

	# 更新每个图层的位置
	for layer_name in layers_config.keys():
		var layer_node = get_node_or_null(layer_name)
		if layer_node:
			var sensitivity = layers_config[layer_name]
			# 目标位置 = 初始位置 + 鼠标偏移 * 敏感度系数
			# 注意：这里的负号决定了移动方向（跟随还是反向）
			layer_node.position = base_positions[layer_name] + (offset * sensitivity)

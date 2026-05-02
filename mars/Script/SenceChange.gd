extends Node

# 1. 声明变量（这就是介绍“老王”）：记录当前在第几关（从0开始数）
var current_level_index: int = 0

# 2. 关卡列表：用数组 [] 更有序，电脑数起来更快
var levels_list = [
	"res://Scenes/Level/level1.tscn", # 记得后缀名要写全 .tscn
    "res://Scenes/Level/level2.tscn"
]

func load_next_level():
	# 序号加 1
	current_level_index += 1
	
	# 检查：如果加完后的序号，还在列表范围内
	if current_level_index < levels_list.size():
		var next_scene_path = levels_list[current_level_index]
		get_tree().change_scene_to_file(next_scene_path)
		print("进入下一关：", next_scene_path)
	else:
		print("恭喜！已经是最后一关了。")

# 给第一关手动重置的方法（备用）
func start_game():
	current_level_index = 0
	get_tree().change_scene_to_file(levels_list[0])

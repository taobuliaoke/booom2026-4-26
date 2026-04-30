extends Node

# 预加载你的关卡路径，方便调用
var levels = {
    "客厅": "res://Scenes/LivingRoom.tscn",
    "花园": "res://Scenes/Garden.tscn"
}

func change_scene(scene_name: String):
    # 1. 找到主场景里的 WorldContainer
    # 注意：这里假设你的 Main 节点在根目录下
    var world = get_tree().root.get_node("Main/WorldContainer")
    
    # 2. 清空当前正在显示的场景
    for child in world.get_children():
        child.queue_free()
    
    # 3. 加载新场景并添加进去
    var new_scene_path = levels[scene_name]
    var new_scene = load(new_scene_path).instantiate()
    world.add_child(new_scene)
    
    print("场景已切换至：", scene_name)
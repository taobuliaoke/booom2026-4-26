extends Resource
class_name LevelData

@export var item_descriptions:Dictionary = {
	"周某": "歪比八",
	"线索A": "这是一个重要的证据。",
	"沈某": "比巴伯"
}

@export var character_data:Dictionary = {
	"沈慧心": {
		"dialog": "好久不见，这是我为你准备的礼物。",
		"items":[
			{
				"name": "钢笔",
				"path":"res://art/UI/ToggleButton.png" ,
				"can_interact": false, # 不可点进次级界面
				"content": ""
			},
			{
				"item_name": "信封",
				"path": "res://art/Evidence/LetterTest.png",# 道具图片路径
				"can_interact": true, 
				"content": "这是一封信。"
			}
			]
	},
	
	
	
	"沈某": {
		"dialog": "别在那边鬼鬼祟祟的！",
		"item_path": "" # 没有道具
	}
}

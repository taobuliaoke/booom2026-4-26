# GameData.gd
extends Node

# 线索表：用于普通的 Interactable 物品
var item_descriptions = {
	"周某": "歪比八",
	"线索A": "这是一个重要的证据。"
}

# 角色表：用于 NPC 的详细交互
var character_data = {
	"周静姝": {
		"dialog": "好久不见，这是我为你准备的礼物。",
		"item_path": "res://art/Evidence/test.png" # 道具图片路径
	},
	"沈某": {
		"dialog": "别在那边鬼鬼祟祟的！",
		"item_path": "" # 没有道具
	}
}

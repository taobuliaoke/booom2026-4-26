extends CanvasLayer
signal request_bird_sound

@onready var rect = $ColorRect

@onready var music_slider = $SettingsBox/MarginContainer/VBoxContainer/MusicVolumeRow/MusicSlider
var music_bus_index : int
var volume_before_change : float # 用来记录修改前的音量

func _ready():
	music_bus_index = AudioServer.get_bus_index("Music")
	# 如果你在主场景里通过 .show() 调用，可以在这里初次隐藏
	self.hide()

# 在主菜单调用 settings_ui.show_settings() 而不是直接 .show()
func show_settings():
	# 记录当前音量，备后续“取消”时恢复
	volume_before_change = AudioServer.get_bus_volume_db(music_bus_index)
	self.show()
	var tween = create_tween()
	# 设置过渡曲线，让弹窗弹出感更丝滑（EASE_OUT 适合弹出）
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# 动画逻辑：透明度从 0 到 1
	 # 假设你有个面板
	
	tween.tween_property(rect, "modulate:a", 1.0, 0.4).from(0.0)

# 滑块拖动逻辑
func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(music_bus_index, value)
	AudioServer.set_bus_mute(music_bus_index, value <= -20)

# --- 确定按钮：直接关闭即可，因为滑块拖动时已经改变了音量 ---
func _on_confirm_button_pressed():
	if MusicManager.has_method("play_se"): # 假设你有音效管理器
		request_bird_sound.emit()
		pass
	# 这里以后可以添加保存到本地 ConfigFile 的逻辑
	self.hide()

# --- 取消按钮：恢复到打开前的音量 ---
func _on_quit_button_pressed():
	# 还原音量
	request_bird_sound.emit()
	AudioServer.set_bus_volume_db(music_bus_index, volume_before_change)
	AudioServer.set_bus_mute(music_bus_index, volume_before_change <= -20)
	music_slider.value = volume_before_change
	self.hide()

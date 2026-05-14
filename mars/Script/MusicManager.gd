# MusicManager.gd
extends Node

var bgm_player: AudioStreamPlayer
var pitch_tween: Tween
var fade_tween: Tween

func _ready():
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	bgm_player.bus = "Master"

# 修改此函数，允许传入一个音乐资源 (stream)
func play_with_fade_in(stream: AudioStream, duration: float = 2.0):
	# 如果正在播放同一首曲子，就不重复播放
	if bgm_player.stream == stream and bgm_player.playing: 
		return
	
	bgm_player.stream = stream
	bgm_player.volume_db = -80
	bgm_player.pitch_scale = 1.0
	bgm_player.play()
	
	if fade_tween: fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(bgm_player, "volume_db", 0.0, duration)

func smooth_pitch(target_pitch: float, duration: float = 0.5):
	if pitch_tween: pitch_tween.kill()
	pitch_tween = create_tween()
	pitch_tween.set_ease(Tween.EASE_OUT)
	pitch_tween.set_trans(Tween.TRANS_SINE)
	# 确保 target_pitch 是正数！
	pitch_tween.tween_property(bgm_player, "pitch_scale", max(0.01, target_pitch), duration)

func fade_out_and_stop(duration: float = 1.0):
	if fade_tween: fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(bgm_player, "volume_db", -80, duration)
	fade_tween.tween_callback(bgm_player.stop)
	
	
func play_se(se_stream: AudioStream, volume_db: float = 0.0):
	if not se_stream: return
	
	# 如果是切换音效，我们可以在这里根据需要限制同时播放的数量
	# 但通常对于标题界面，让它自由重叠（Polyphony）听起来反而更自然
	var se_player = AudioStreamPlayer.new()
	add_child(se_player)
	se_player.stream = se_stream
	se_player.volume_db = volume_db
	se_player.bus = "Master" 
	se_player.play()
	se_player.finished.connect(se_player.queue_free)

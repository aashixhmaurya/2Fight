extends Node

## Global background music — keeps playing across main fight and Hell.
const TRACK_PATH = "res://assets/music/BG 1 GREEN.ogg"
## Soft bed under gameplay (matched to last quiet level).
const VOLUME_DB = -27.0
const SILENT_DB = -80.0

var player: AudioStreamPlayer


func _ready():
	player = AudioStreamPlayer.new()
	player.name = "Player"
	player.bus = "Master"
	player.volume_db = VOLUME_DB
	add_child(player)

	var stream = load(TRACK_PATH)
	if stream == null:
		push_warning("BGM: could not load " + TRACK_PATH)
		return

	if stream is AudioStreamOggVorbis:
		stream.loop = true

	player.stream = stream
	player.play()


func set_volume_db(db: float):
	if player:
		player.volume_db = db


func fade_volume(to_db: float, duration: float):
	if player == null:
		return
	var tw = create_tween()
	tw.tween_property(player, "volume_db", to_db, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


func fade_out(duration: float):
	await fade_volume(SILENT_DB, duration)


func fade_in(duration: float):
	if player and not player.playing and player.stream:
		player.play()
	await fade_volume(VOLUME_DB, duration)


func stop_music():
	if player:
		player.stop()


func play_music():
	if player and player.stream and not player.playing:
		player.volume_db = VOLUME_DB
		player.play()

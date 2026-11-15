extends Node

## One-shot combat effects from assets/music/effects (keyed by name).
const SFX_VOLUME_DB = -8.0
const PATHS = {
	"empty-attack-swing": "res://assets/music/effects/empty-attack-swing.mp3",
	"damage": "res://assets/music/effects/damage.mp3",
	"pig-death": "res://assets/music/effects/pig-death.wav",
	"red-death": "res://assets/music/effects/red-death.wav",
}

var streams: Dictionary = {}


func _ready():
	for key in PATHS:
		var stream = load(PATHS[key])
		if stream == null:
			push_warning("SFX: missing " + PATHS[key])
			continue
		streams[key] = stream


func play(effect_name: String):
	if not streams.has(effect_name):
		push_warning("SFX: unknown effect '" + effect_name + "'")
		return

	var p = AudioStreamPlayer.new()
	p.stream = streams[effect_name]
	p.volume_db = SFX_VOLUME_DB
	p.bus = "Master"
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func play_death_for(player_number: int):
	# P1 = red demon, P2 = pig / boar
	if player_number == 1:
		play("red-death")
	else:
		play("pig-death")

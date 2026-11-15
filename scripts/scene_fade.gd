extends CanvasLayer

## Soft full-screen fade between arenas, with a themed bridge card into Hell.
const FADE_TIME = 0.4
const CARD_HOLD = 2.2

var overlay: ColorRect
var card: Control
var defeat_label: Label
var next_label: Label
var detail_label: Label


func _ready():
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	_build_card()


func _build_overlay():
	overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)


func _build_card():
	card = Control.new()
	card.name = "BridgeCard"
	card.visible = false
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.modulate.a = 0.0
	add_child(card)

	var wash = ColorRect.new()
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(0.04, 0.02, 0.02, 1)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(wash)

	var ember = ColorRect.new()
	ember.set_anchors_preset(Control.PRESET_CENTER)
	ember.offset_left = -420
	ember.offset_top = -160
	ember.offset_right = 420
	ember.offset_bottom = 160
	ember.color = Color(0.55, 0.12, 0.05, 0.22)
	ember.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(ember)

	var rule_top = ColorRect.new()
	rule_top.set_anchors_preset(Control.PRESET_CENTER)
	rule_top.offset_left = -280
	rule_top.offset_top = -118
	rule_top.offset_right = 280
	rule_top.offset_bottom = -116
	rule_top.color = Color(1.0, 0.45, 0.18, 0.85)
	rule_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rule_top)

	defeat_label = Label.new()
	defeat_label.set_anchors_preset(Control.PRESET_CENTER)
	defeat_label.offset_left = -420
	defeat_label.offset_top = -100
	defeat_label.offset_right = 420
	defeat_label.offset_bottom = -40
	defeat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	defeat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	defeat_label.text = "PLAYER 1 DEFEATED"
	UiTheme.apply_label(defeat_label, 22, Color(1.0, 0.55, 0.22, 1))
	card.add_child(defeat_label)

	next_label = Label.new()
	next_label.set_anchors_preset(Control.PRESET_CENTER)
	next_label.offset_left = -400
	next_label.offset_top = -10
	next_label.offset_right = 400
	next_label.offset_bottom = 36
	next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_label.text = "NEXT - HELL"
	UiTheme.apply_label(next_label, 16, Color(0.95, 0.9, 0.85, 1))
	card.add_child(next_label)

	detail_label = Label.new()
	detail_label.set_anchors_preset(Control.PRESET_CENTER)
	detail_label.offset_left = -480
	detail_label.offset_top = 44
	detail_label.offset_right = 480
	detail_label.offset_bottom = 110
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.text = "Fight the black shadow.\nWin to rise again."
	UiTheme.apply_label(detail_label, 10, Color(0.78, 0.62, 0.5, 1))
	card.add_child(detail_label)

	var rule_bot = ColorRect.new()
	rule_bot.set_anchors_preset(Control.PRESET_CENTER)
	rule_bot.offset_left = -280
	rule_bot.offset_top = 118
	rule_bot.offset_right = 280
	rule_bot.offset_bottom = 120
	rule_bot.color = Color(1.0, 0.45, 0.18, 0.85)
	rule_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rule_bot)


func _fill_defeat_card():
	var loser = GameState.loser_number
	defeat_label.text = "PLAYER %d DEFEATED" % loser
	next_label.text = "NEXT - HELL"
	detail_label.text = "Clear Hell to earn the FINAL power round.\nLose Hell and it is game over."


func fade_to_black():
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(overlay, "color:a", 1.0, FADE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if BGM.player:
		tw.tween_property(BGM.player, "volume_db", BGM.SILENT_DB, FADE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


func fade_from_black():
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(overlay, "color:a", 0.0, FADE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if BGM.player:
		if not BGM.player.playing and BGM.player.stream:
			BGM.player.play()
		tw.tween_property(BGM.player, "volume_db", BGM.VOLUME_DB, FADE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _show_card():
	_fill_defeat_card()
	card.visible = true
	card.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished


func _hide_card():
	var tw = create_tween()
	tw.tween_property(card, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished
	card.visible = false


func change_scene(path: String):
	await fade_to_black()
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await fade_from_black()


func go_to_hell():
	## Freeze already happened in main — fade out, bridge card, then Hell fade in.
	await fade_to_black()
	await _show_card()
	await get_tree().create_timer(CARD_HOLD).timeout
	await _hide_card()
	get_tree().change_scene_to_file("res://scenes/hell.tscn")
	await get_tree().process_frame
	await fade_from_black()

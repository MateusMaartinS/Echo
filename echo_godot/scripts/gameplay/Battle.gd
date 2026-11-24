extends Node2D

const LEVEL_SELECT_SCENE: String = "res://scenes/LevelSelect.tscn"
const COUNT_IN_BEATS: int = 3   # três preparações; VAI entra no quarto tempo

const JUDGMENT_COLORS: Dictionary = {
	"Perfect": Color("#174A9A"),
	"Good": Color(0.10, 0.38, 0.68, 1.0),
	"Bad": Color(0.85, 0.55, 0.12, 1.0),
	"Miss": Color(0.75, 0.18, 0.18, 1.0),
	"Error": Color(0.75, 0.18, 0.18, 1.0),
	"Fire": Color(0.90, 0.28, 0.10, 1.0),
	"Ice": Color(0.15, 0.55, 0.80, 1.0),
	"HoldOK": Color("#174A9A"),
	"HoldBreak": Color(0.75, 0.18, 0.18, 1.0),
}

# Nome do efeito sonoro (audio/sfx/<nome>.wav) tocado em cada julgamento.
# Se o arquivo não existir, não toca nada.
const JUDGMENT_SFX: Dictionary = {
	"Perfect": "hit_perfect",
	"Good": "hit_good",
	"Bad": "hit_bad",
	"Miss": "miss",
	"Error": "error",
	"Fire": "fire",
	"Ice": "ice",
	"HoldOK": "hold_ok",
	"HoldBreak": "hold_break",
}

const JUDGMENT_TEXT: Dictionary = {
	"Fire": "FOGO!  ENERGIA",
	"Ice": "GELO!  TECLAS CONGELADAS",
	"HoldOK": "SEGUROU!  +BÔNUS",
	"HoldBreak": "SOLTOU CEDO!",
}

var level: Dictionary = {}
var chart: Dictionary = {}
var phrases: Array = []
var events: Array = []
var response_delay_beats: float = 4.0
var phase: String = "IDLE"
var first_response_beat: float = INF
var last_player_beat: float = 0.0
var opponent_last_beat: float = 0.0
var season_fx: SeasonEffects
var pause_menu: PauseMenu
var paused: bool = false
var counting_in: bool = false
var count_token: int = 0
var starting_song: AudioStream
var restarting: bool = false
var season_view: SeasonBattleView

@onready var opponent_spawner: NoteSpawner = $OpponentSpawner
@onready var player_spawner: NoteSpawner = $PlayerSpawner
@onready var judge: Judge = $Judge
@onready var player_input: PlayerInput = $PlayerInput
@onready var score: ScoreManager = $ScoreManager
@onready var hud: CanvasLayer = $HUD
@onready var phase_label: Label = $HUD/Phase
@onready var round_info_label: Label = $HUD/RoundInfo
@onready var judgment_label: Label = $HUD/Judgment
@onready var arena: Node2D = $Background
@onready var characters: Node2D = $Characters

func _ready() -> void:
	MenuMusic.stop()
	level = LevelDB.selected()
	chart = ChartIO.load_chart(str(level["chart"]))
	chart = ChartData.ensure_shape(chart, level)
	phrases = chart.get("phrases", []) as Array
	events = chart.get("events", []) as Array
	response_delay_beats = maxf(float(chart.get("response_delay_beats", 4.0)), 0.0)

	Conductor.stop()
	Conductor.set_bpm(float(chart.get("bpm", 144.0)))
	Conductor.offset_seconds = GameSettings.sync_offset_ms / 1000.0
	judgment_label.pivot_offset = judgment_label.size / 2.0
	$HUD/Back.focus_mode = Control.FOCUS_NONE
	$HUD/Back.text = "PAUSA"
	$HUD/Help.text = "D F J K  ou  SETAS    •    segure nas notas longas    •    R = REINICIAR    ESC = PAUSA    F11 = TELA CHEIA"

	judge.setup(player_spawner)
	player_input.judge = judge
	judge.judged.connect(_on_judged)
	score.score_changed.connect(_refresh_score_ui)
	score.combo_changed.connect(_refresh_combo_ui)
	score.energy_changed.connect(_refresh_energy_ui)
	score.reset()

	season_fx = SeasonEffects.new()
	add_child(season_fx)
	season_fx.setup(events, opponent_spawner, player_spawner, judge)

	pause_menu = BattlePauseMenu.new() if str(level.get("season", "")) in BossCatalog.SPRITE_BOSSES else PauseMenu.new()
	add_child(pause_menu)
	pause_menu.resume_pressed.connect(_resume_with_count_in)
	pause_menu.restart_pressed.connect(_on_restart_pressed)
	pause_menu.quit_pressed.connect(_go_to_level_select)
	if str(level.get("season", "")) in BossCatalog.SPRITE_BOSSES:
		_apply_season_presentation()

	var all_opponent_notes: Array = []
	var all_player_notes: Array = []
	first_response_beat = INF
	last_player_beat = 0.0
	opponent_last_beat = 0.0

	for raw_phrase in phrases:
		if not (raw_phrase is Dictionary):
			continue
		var phrase: Dictionary = raw_phrase as Dictionary
		var notes: Array = phrase.get("notes", []) as Array
		if notes.is_empty():
			continue

		var start_beat: float = float(phrase.get("start_beat", 0.0))
		var end_beat: float = float(phrase.get("end_beat", start_beat + 1.0))
		var response_start: float = start_beat + response_delay_beats
		var phrase_last_player_beat: float = end_beat + response_delay_beats

		first_response_beat = minf(first_response_beat, response_start)
		last_player_beat = maxf(last_player_beat, phrase_last_player_beat)
		opponent_last_beat = maxf(opponent_last_beat, end_beat)

		for raw_note in notes:
			if not (raw_note is Dictionary):
				continue
			var source: Dictionary = raw_note as Dictionary
			all_opponent_notes.append(source.duplicate(true))

			var player_note: Dictionary = source.duplicate(true)
			player_note["beat"] = float(source.get("beat", 0.0)) + response_delay_beats
			all_player_notes.append(player_note)

	characters.setup_lord_notes(all_opponent_notes)
	opponent_spawner.clear_all()
	player_spawner.clear_all()

	if all_opponent_notes.is_empty():
		phase_label.text = "CHART VAZIO — VOLTE AO EDITOR"
		player_input.player_turn = false
		return

	score.total_notes = ChartData.count_scoring_notes(phrases)

	var stream_path: String = LevelDB.resolve_audio(level)
	var stream: AudioStream = null
	if stream_path != "":
		stream = load(stream_path) as AudioStream
	if stream == null:
		push_error("Não foi possível carregar o áudio da fase: " + LevelDB.suggested_audio_path(level))
		phase_label.text = "ÁUDIO NÃO ENCONTRADO"
		return

	starting_song = stream
	opponent_spawner.spawn_chart_notes(all_opponent_notes, 0.0, 0.0)
	player_spawner.spawn_chart_notes(all_player_notes, 0.0, 0.0)
	player_input.player_turn = false
	phase = "OPPONENT"
	phase_label.text = "%s — OBSERVE" % BossCatalog.display_name(str(level.get("season", "tutorial")))
	round_info_label.text = "%s  •  RESPOSTA + %.2f BEATS" % [str(level.get("name", "")), response_delay_beats]
	arena.set_active_field(phase)
	characters.set_active_side(phase)
	paused = true
	player_input.set_blocked(true)
	judge.set_enabled(false)
	_resume_with_count_in()

func _apply_season_presentation() -> void:
	arena.hide()
	arena.set_process(false)
	season_view = SeasonBattleView.new()
	season_view.name = "SeasonView"
	add_child(season_view)
	move_child(season_view, 1)
	season_view.setup(self, score)
	arena = season_view
	player_spawner.use_pixel_layout(true)
	opponent_spawner.use_pixel_layout(false)
	characters.apply_pixel_layout()
	characters.lord_note_played.connect(season_view.pulse_lord)

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_R):
		if not has_meta("r_pressed"):
			set_meta("r_pressed", true)
			_on_restart_pressed()
	else:
		remove_meta("r_pressed")

	# Pausado (menu aberto ou contando 1-2-3-4): tudo congelado.
	if paused or restarting:
		return

	var beat: float = Conductor.get_current_beat()
	if phase == "FINISHED":
		return

	player_input.player_turn = beat >= first_response_beat and beat <= last_player_beat + 0.5
	judge.set_enabled(player_input.player_turn)

	var player_window_active: bool = beat >= first_response_beat and beat <= last_player_beat + 0.5
	var opponent_window_active: bool = _is_opponent_window_active(beat)

	if player_window_active:
		if phase != "PLAYER":
			phase = "PLAYER"
			phase_label.text = "PLAYER — REPITA"
			arena.set_active_field(phase)
			characters.set_active_side(phase)
	elif opponent_window_active:
		if phase != "OPPONENT":
			phase = "OPPONENT"
			phase_label.text = "%s — OBSERVE" % BossCatalog.display_name(str(level.get("season", "tutorial")))
			arena.set_active_field(phase)
			characters.set_active_side(phase)
	elif beat > last_player_beat + 0.8:
		_finish(true)

func _is_opponent_window_active(beat: float) -> bool:
	for raw_phrase in phrases:
		if not (raw_phrase is Dictionary):
			continue
		var phrase: Dictionary = raw_phrase as Dictionary
		var start_beat: float = float(phrase.get("start_beat", 0.0))
		var end_beat: float = float(phrase.get("end_beat", start_beat))
		if beat >= start_beat and beat <= end_beat:
			return true
	return false

func _finish(victory: bool) -> void:
	if phase == "FINISHED":
		return
	phase = "FINISHED"
	player_input.player_turn = false
	judge.set_enabled(false)
	phase_label.text = "VICTORY" if victory else "GAME OVER"
	if victory:
		Conductor.stop()

	# Estrelas = fração de notas acertadas (limiares em Progress.gd).
	var ratio: float = score.get_hit_ratio()
	var reward_id: String = str(level.get("season", ""))
	var reward_was_locked: bool = SkinCatalog.is_known(reward_id) and not SkinCatalog.is_unlocked(reward_id)
	var outcome: Dictionary = Progress.submit(str(level["id"]), victory, ratio, score.score, score.max_combo)
	var stars: int = int(outcome["stars"])

	$HUD/ResultPanel.visible = true
	$HUD/ResultPanel/Title.text = "ECHO COMPLETE" if victory else "PRESENTATION FAILED"
	$HUD/ResultPanel/Stats.position.y = 122.0
	$HUD/ResultPanel/Stats.text = "SCORE  %d\nACCURACY  %.1f%%\nNOTES HIT  %d / %d\nMAX COMBO  %d\nGRADE  %s" % [score.score, score.get_accuracy(), score.hit_notes, score.total_notes, score.max_combo, score.get_grade()]

	var hint_parts: Array = []
	if not victory:
		hint_parts.append("A energia acabou — sem estrelas desta vez")
	else:
		if bool(outcome["new_best"]):
			hint_parts.append("NOVO RECORDE!")
		var next_threshold: float = Progress.next_threshold(stars)
		if next_threshold > 0.0:
			hint_parts.append("próxima estrela: %.0f%% das notas" % (next_threshold * 100.0))
		else:
			hint_parts.append("TODAS AS ESTRELAS!")
	var hint: Label = $HUD/ResultPanel/Hint
	hint.position.y = 258.0
	hint.size.y = 54.0
	hint.text = " • ".join(hint_parts) + "\nR = reiniciar  •  ESC = fases"
	if victory and reward_was_locked and SkinCatalog.is_unlocked(reward_id):
		var reward_text: String = "NOVAS ROUPAS: %s!" % str(level.get("name", "")) if reward_id in ["spring","winter","summer","autumn"] else "NOVA ROUPA: %s!" % str(SkinCatalog.get_skin(reward_id)["name"])
		hint.text = reward_text + " Veja no guarda-roupa.\n" + hint.text

	var star_row: StarRow = StarRow.new()
	star_row.total = Progress.MAX_STARS
	star_row.position = Vector2(150.0, 84.0)
	star_row.size = Vector2(200.0, 36.0)
	$HUD/ResultPanel.add_child(star_row)
	if stars > 0:
		var star_tween: Tween = create_tween()
		star_tween.tween_interval(0.35)
		star_tween.tween_property(star_row, "filled", float(stars), 0.35 * float(stars))
	if season_view != null:
		season_view.style_result(victory)

func _on_judged(result: String, difference_ms: float, lane: int) -> void:
	if phase != "PLAYER" or paused:
		return
	score.register_judgment(result)
	if season_view != null:
		season_view.show_judgment(result, lane)

	Sfx.play(str(JUDGMENT_SFX.get(result, "")))

	if result == "Fire":
		judgment_label.text = "FOGO!  %.0f ENERGIA" % ScoreManager.ENERGY_FIRE
	elif JUDGMENT_TEXT.has(result):
		judgment_label.text = str(JUDGMENT_TEXT[result])
	else:
		judgment_label.text = result.to_upper() + "  %+.0f ms" % difference_ms
	judgment_label.add_theme_color_override("font_color", JUDGMENT_COLORS.get(result, Color("#174A9A")))
	judgment_label.modulate.a = 1.0
	judgment_label.scale = Vector2(1.15, 1.15)
	var judgment_tween: Tween = create_tween()
	judgment_tween.tween_property(judgment_label, "scale", Vector2(1.0, 1.0), 0.12)
	if lane >= 0 and result in ["Perfect", "Good", "Bad"]:
		var hold_seconds: float = 0.0
		if judge.holding.has(lane):
			var held: RhythmNote = judge.holding[lane] as RhythmNote
			hold_seconds = maxf(held.end_time - Conductor.get_song_position(), 0.0)
		characters.pulse_note(lane, hold_seconds)
	elif lane >= 0 and result in ["HoldOK", "HoldBreak"]:
		characters.release_pose(lane)
	var tween: Tween = create_tween()
	tween.tween_interval(0.30)
	tween.tween_property(judgment_label, "modulate:a", 0.0, 0.25)
	if score.energy <= 0.0:
		_finish(false)

func _refresh_score_ui(value: int) -> void:
	$HUD/TopBar/Score.text = "SCORE  %06d" % value

func _refresh_combo_ui(value: int) -> void:
	$HUD/TopBar/Combo.text = "COMBO  x%d" % value

func _refresh_energy_ui(value: float) -> void:
	$HUD/TopBar/Energy.value = value
	$HUD/TopBar/Energy.tooltip_text = "ENERGIA %.0f%%" % value

# --- Pausa --------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_on_escape()

func _on_escape() -> void:
	if restarting:
		return
	if phase == "FINISHED" or phase == "IDLE":
		_go_to_level_select()
	elif counting_in:
		_cancel_count_in()
	elif paused:
		if not pause_menu.back_to_pause():
			_resume_with_count_in()
	else:
		_pause_game()

# Botão PAUSA do HUD.
func _on_back_pressed() -> void:
	if restarting:
		return
	if phase == "FINISHED" or phase == "IDLE":
		_go_to_level_select()
	elif counting_in:
		_cancel_count_in()
	elif not paused:
		_pause_game()

func _pause_game() -> void:
	if paused or phase == "FINISHED" or phase == "IDLE":
		return
	paused = true
	Conductor.pause()
	player_input.player_turn = false
	player_input.set_blocked(true)
	judge.set_enabled(false)
	judge.forgive_active_holds()
	pause_menu.show_pause()

# 1, 2, 3; música e VAI entram juntos no quarto tempo.
func _resume_with_count_in() -> void:
	if not paused or counting_in:
		return
	pause_menu.hide_pause()
	counting_in = true
	count_token += 1
	var token: int = count_token
	var beat_seconds: float = Conductor.seconds_per_beat
	for i in range(COUNT_IN_BEATS):
		pause_menu.show_count(i + 1)
		Sfx.play("count_accent" if i == 0 else "count_tick")
		await get_tree().create_timer(beat_seconds).timeout
		if token != count_token or not counting_in:
			return
	pause_menu.show_count(4)
	Sfx.play("count_accent")
	counting_in = false
	paused = false
	player_input.set_blocked(false)
	if starting_song != null:
		Conductor.play_stream(starting_song, 0.0)
		starting_song = null
	else:
		Conductor.resume()
	await get_tree().create_timer(beat_seconds).timeout
	if token == count_token and not paused:
		pause_menu.hide_count()

# ESC durante a contagem: volta pro menu de pausa.
func _cancel_count_in() -> void:
	count_token += 1
	counting_in = false
	pause_menu.show_pause()

func _on_restart_pressed() -> void:
	if restarting:
		return
	restarting = true
	count_token += 1
	counting_in = false
	paused = true
	player_input.set_blocked(true)
	judge.set_enabled(false)
	Conductor.pause()
	pause_menu.hide_pause()
	pause_menu.hide_count()
	await Conductor.rewind_preview()
	get_tree().reload_current_scene()

func _go_to_level_select() -> void:
	Conductor.stop()
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if Conductor != null:
			Conductor.stop()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		# Alt-tab / janela perdeu o foco: pausa sozinho.
		if counting_in:
			_cancel_count_in()
		elif not paused:
			_pause_game()

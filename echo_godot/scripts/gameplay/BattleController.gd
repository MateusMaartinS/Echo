extends Node2D
class_name BattleController

signal phase_changed(phase_name: String)
signal battle_finished(victory: bool)

enum Phase { INTRO, OPPONENT, PLAYER, RESULT, GAME_OVER }

static var instance: BattleController

@onready var chart: RhythmChart = preload("res://charts/test_song.tres")
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var opponent_spawner: NoteSpawner = $OpponentSpawner
@onready var player_spawner: NoteSpawner = $PlayerSpawner
@onready var judge: Judge = $Judge
@onready var score_manager: ScoreManager = $ScoreManager
@onready var hud: CanvasLayer = $HUD

var phase: Phase = Phase.INTRO
var round_index: int = 0
var current_round: RoundData
var phase_start_time: float = 0.0
var phase_end_time: float = 0.0
var intro_end_time: float = 1.0

func _ready() -> void:
    instance = self
    score_manager.reset()
    judge.setup(player_spawner)
    judge.judged.connect(_on_judged)
    Conductor.setup(music_player, chart.bpm)
    Conductor.song_finished.connect(_on_song_finished)
    _update_phase_label("READY")
    start_battle()

func _process(_delta: float) -> void:
    if Input.is_key_pressed(KEY_R):
        # Evita repetir restart em vários frames.
        if not has_meta("r_pressed"):
            set_meta("r_pressed", true)
            restart_battle()
    else:
        remove_meta("r_pressed")

    if phase == Phase.INTRO and Conductor.running:
        if Conductor.song_position >= intro_end_time:
            start_opponent_turn()
    elif phase == Phase.OPPONENT:
        if Conductor.song_position >= phase_end_time:
            start_player_turn()
    elif phase == Phase.PLAYER:
        if Conductor.song_position >= phase_end_time:
            finish_player_round()

static func is_player_turn() -> bool:
    return instance != null and instance.phase == Phase.PLAYER

func start_battle() -> void:
    restart_battle()

func restart_battle() -> void:
    phase = Phase.INTRO
    round_index = 0
    current_round = null
    score_manager.reset()
    opponent_spawner.clear_all()
    player_spawner.clear_all()
    judge.set_enabled(false)
    hud.get_node("ResultPanel").visible = false
    Conductor.play_music(chart.song)
    intro_end_time = 1.0
    _update_phase_label("READY • OPPONENT")
    _show_turn_round(1, "WATCH THE ECHO")

func start_opponent_turn() -> void:
    if round_index >= chart.rounds.size():
        _show_result(true)
        return
    current_round = chart.rounds[round_index]
    phase = Phase.OPPONENT
    judge.set_enabled(false)
    phase_start_time = Conductor.song_position + 0.15
    phase_end_time = phase_start_time + current_round.duration + 0.15
    opponent_spawner.schedule_sequence(current_round.notes, phase_start_time)
    _update_phase_label("OPPONENT • WATCH")
    _show_turn_round(round_index + 1, "WATCH THE ECHO")
    phase_changed.emit("OPPONENT")

func start_player_turn() -> void:
    phase = Phase.PLAYER
    judge.set_enabled(true)
    phase_start_time = Conductor.song_position + 0.15
    phase_end_time = phase_start_time + current_round.duration + 0.15
    player_spawner.schedule_sequence(current_round.notes, phase_start_time)
    score_manager.total_notes += current_round.notes.size()
    _update_phase_label("PLAYER • REPEAT")
    _show_turn_round(round_index + 1, "REPEAT THE SEQUENCE")
    phase_changed.emit("PLAYER")

func finish_player_round() -> void:
    judge.set_enabled(false)
    if score_manager.energy <= 0.0:
        _show_result(false)
        return
    round_index += 1
    if round_index >= chart.rounds.size():
        _show_result(true)
    else:
        start_opponent_turn()

func _on_judged(result: String, difference_ms: float, lane: int) -> void:
    score_manager.register_judgment(result)
    _show_judgment(result, difference_ms, lane)
    if score_manager.energy <= 0.0:
        _show_result(false)

func _on_song_finished() -> void:
    if phase != Phase.RESULT and phase != Phase.GAME_OVER:
        _show_result(score_manager.energy > 0.0)

func _show_result(victory: bool) -> void:
    phase = Phase.RESULT if victory else Phase.GAME_OVER
    judge.set_enabled(false)
    player_spawner.clear_all()
    opponent_spawner.clear_all()
    _update_phase_label("VICTORY" if victory else "GAME OVER")
    hud.get_node("ResultPanel/Title").text = "ECHO COMPLETE" if victory else "PRESENTATION FAILED"
    hud.get_node("ResultPanel/Stats").text = "SCORE  %d\nACCURACY  %.1f%%\nMAX COMBO  %d\nGRADE  %s" % [score_manager.score, score_manager.get_accuracy(), score_manager.max_combo, score_manager.get_grade()]
    hud.get_node("ResultPanel").visible = true
    battle_finished.emit(victory)
    if victory:
        Conductor.stop_music()

func _show_judgment(result: String, difference_ms: float, _lane: int) -> void:
    var text := result
    if result != "Error":
        text += "  %+d ms" % int(round(difference_ms))
    var label := hud.get_node("Judgment") as Label
    label.text = text
    label.modulate.a = 1.0
    var tween: Tween = create_tween()
    tween.tween_interval(0.30)
    tween.tween_property(label, "modulate:a", 0.0, 0.25)

func _show_turn_round(number: int, subtitle: String) -> void:
    hud.get_node("RoundInfo").text = "ROUND %02d  •  %s" % [number, subtitle]

func _update_phase_label(text: String) -> void:
    hud.get_node("Phase").text = text

func _exit_tree() -> void:
    if instance == self:
        instance = null

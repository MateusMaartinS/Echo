extends Node2D
class_name NoteSpawner

@export var note_scene: PackedScene
@export var spawn_x: float = 1180.0
@export var target_x: float = 302.0
@export var travel_time: float = 1.50
@export var lane_y: Array[float] = [178.0, 220.0, 262.0, 304.0]
@export var note_modulate: Color = Color("#174A9A")

var active_notes: Array[RhythmNote] = []
var pending_spawns: Array[Dictionary] = []
var pixel_style: bool = false

func use_pixel_layout(player_field: bool) -> void:
    pixel_style=true
    target_x=BattleHudStyle.HIT_X
    spawn_x=BattleHudStyle.SPAWN_X
    lane_y=BattleHudStyle.PLAYER_LANES.duplicate() if player_field else BattleHudStyle.OPPONENT_LANES.duplicate()

# notes: lista de dicionários do chart ({beat, lane, duration?, type?}).
func spawn_chart_notes(notes: Array, chart_start_beat: float, play_start_time: float) -> void:
    for raw in notes:
        if not (raw is Dictionary):
            continue
        var source: Dictionary = raw as Dictionary
        var beat: float = float(source.get("beat", 0.0))
        var lane: int = int(source.get("lane", 0))
        var type_name: String = str(source.get("type", "normal"))
        var hold_beats: float = float(source.get("duration", 0.0))
        var target_time: float = play_start_time + ((beat - chart_start_beat) * Conductor.seconds_per_beat)
        pending_spawns.append({
            "spawn_time": target_time - travel_time,
            "hit_time": target_time,
            "lane": lane,
            "type": type_name,
            "hold_seconds": hold_beats * Conductor.seconds_per_beat
        })
    pending_spawns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return float(a["spawn_time"]) < float(b["spawn_time"])
    )

func _process(_delta: float) -> void:
    var now: float = Conductor.get_song_position()
    while pending_spawns.size() > 0 and float(pending_spawns[0]["spawn_time"]) <= now:
        var info: Dictionary = pending_spawns.pop_front()
        spawn_note(int(info["lane"]), float(info["hit_time"]), str(info["type"]), float(info["hold_seconds"]))

    # Limpeza das notas que já passaram (Lorde) ou que ninguém julgou.
    for note in active_notes:
        if not is_instance_valid(note):
            continue
        if note.judged or note.is_holding:
            continue
        if now > note.end_time + 0.25:
            note.mark_judged()

func spawn_note(lane: int, hit_time: float, type_name: String = "normal", hold_seconds: float = 0.0) -> void:
    if note_scene == null or lane < 0 or lane >= lane_y.size():
        return
    var note: RhythmNote = note_scene.instantiate() as RhythmNote
    note.pixel_style=pixel_style
    add_child(note)
    note.position.y = lane_y[lane]
    note.set_note_color(note_modulate)
    note.setup(lane, hit_time, travel_time, spawn_x, target_x, type_name, hold_seconds)
    note.tree_exiting.connect(_on_note_exiting.bind(note))
    active_notes.append(note)

func _on_note_exiting(note: RhythmNote) -> void:
    active_notes.erase(note)

# Nota não julgada mais antiga da lane (usada só pra mostrar o desvio em
# apertos "perdidos").
func get_pending_note(lane: int) -> RhythmNote:
    var candidate: RhythmNote = null
    for note in active_notes:
        if not is_instance_valid(note) or note.judged or note.is_holding or note.lane != lane:
            continue
        if candidate == null or note.hit_time < candidate.hit_time:
            candidate = note
    return candidate

# Nota da lane mais próxima do instante `now`, dentro de `window` segundos.
func get_best_note(lane: int, now: float, window: float) -> RhythmNote:
    var best: RhythmNote = null
    var best_diff: float = INF
    for note in active_notes:
        if not is_instance_valid(note) or note.judged or note.is_holding or note.lane != lane:
            continue
        var diff: float = absf(now - note.hit_time)
        if diff <= window and diff < best_diff:
            best = note
            best_diff = diff
    return best

func clear_all() -> void:
    pending_spawns.clear()
    for note in active_notes:
        if is_instance_valid(note):
            note.queue_free()
    active_notes.clear()

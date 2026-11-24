extends Node2D

signal lord_note_played(lane: int)

# Paper puppets outside the lanes. Both use the music clock, including overlaps.
@export var ink := Color("#174A9A")
@export var highlight := Color(0.85, 0.55, 0.12, 1.0)

var player_base := Vector2(82.0, 206.0)
var opponent_base := Vector2(82.0, 451.0)
var musician: PaperMusician
var lord: PaperMusician
var lord_name: String = "LORDE"
var active_side: String = "OPPONENT"
var pulse: float = 0.0
var lord_notes: Array[Dictionary] = []
var next_lord_note: int = 0
var pixel_layout: bool = false
var normalization: Dictionary = {}

func apply_pixel_layout() -> void:
    pixel_layout=true
    if musician is SpritePlayer:
        normalization["player"]=BattleHudStyle.fit_sprite(musician as SpritePlayer,BattleHudStyle.HERO_HEIGHT,BattleHudStyle.HERO_FEET)
    if lord is SpritePlayer:
        normalization["boss"]=BattleHudStyle.fit_sprite(lord as SpritePlayer,BattleHudStyle.BOSS_HEIGHT,BattleHudStyle.BOSS_FEET)
    queue_redraw()

func _ready() -> void:
    musician = SkinCatalog.create_player()
    musician.position = player_base
    musician.scale = Vector2(0.83, 0.83)
    add_child(musician)
    var season: String = str(LevelDB.selected().get("season", "tutorial"))
    lord = BossCatalog.create_lord(season)
    lord_name = BossCatalog.display_name(season)
    lord.position = opponent_base
    lord.scale = Vector2(0.83, 0.83)
    add_child(lord)

func setup_lord_notes(notes: Array) -> void:
    lord_notes.clear()
    next_lord_note = 0
    for raw in notes:
        var note: Dictionary = raw
        lord_notes.append({
            "time": Conductor.beat_to_seconds(float(note.get("beat", 0.0))),
            "lane": int(note.get("lane", 0)),
            "duration": Conductor.beat_to_seconds(float(note.get("duration", 0.0))) if str(note.get("type", "normal")) == "normal" else 0.0
        })
    lord_notes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["time"]) < float(b["time"]))

func _process(delta: float) -> void:
    var playing: bool = Conductor.is_playing()
    if playing:
        pulse += delta
        var now: float = Conductor.get_song_position()
        while next_lord_note < lord_notes.size() and float(lord_notes[next_lord_note]["time"]) <= now:
            var note: Dictionary = lord_notes[next_lord_note]
            lord.play_pose(int(note["lane"]), float(note["duration"]))
            lord_note_played.emit(int(note["lane"]))
            next_lord_note += 1
    for puppet in [musician, lord]:
        puppet.rhythm_beat = Conductor.get_current_beat()
        puppet.frozen = not playing
    queue_redraw()

func set_active_side(side_name: String) -> void:
    active_side = side_name

func pulse_note(lane: int, hold_seconds: float = 0.0) -> void:
    musician.play_pose(lane, hold_seconds)

func release_pose(lane: int) -> void:
    musician.release_pose(lane)

func _draw() -> void:
    if pixel_layout:
        return
    _draw_halo(player_base + Vector2(0,-8), active_side == "PLAYER")
    _draw_halo(opponent_base + Vector2(0,-8), active_side == "OPPONENT")
    draw_string(ThemeDB.fallback_font, Vector2(42,316), "PLAYER", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, highlight if active_side == "PLAYER" else ink)
    draw_string(ThemeDB.fallback_font, Vector2(20,561), lord_name, HORIZONTAL_ALIGNMENT_CENTER, 124, 15, highlight if active_side == "OPPONENT" else ink)

func _draw_halo(center: Vector2, is_active: bool) -> void:
    if not is_active:
        return
    var radius: float = 46.0 + sin(pulse * 3.0) * 3.0
    draw_circle(center, radius, Color(highlight.r, highlight.g, highlight.b, 0.14))
    draw_arc(center, radius, 0, TAU, 40, Color(highlight.r, highlight.g, highlight.b, 0.5), 2.0, true)

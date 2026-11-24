extends Control

# Piano-roll do editor.
#
# A grade usa 4/4: cada 4 beats = 1 compasso. O beat 0 é o início do áudio.
# O SNAP controla a menor subdivisão usada pra posicionar notas.
#
# Mouse (nas lanes do LORDE):
#   - clique simples numa lane vazia  -> cria nota
#   - clique-e-ARRASTE pra direita    -> cria nota LONGA (segurar)
#   - clique numa nota existente      -> apaga a nota
# Trilha de eventos (só na PRIMAVERA, ferramenta FLOR):
#   - clique-e-arraste cria uma flor; clique numa flor apaga.

const INK: Color = Color("#174A9A")
const GRID_SUB: Color = Color(0.09, 0.29, 0.60, 0.08)
const GRID_BEAT: Color = Color(0.09, 0.29, 0.60, 0.22)
const GRID_BAR: Color = Color(0.09, 0.29, 0.60, 0.42)
const GRID: Color = Color(0.09, 0.29, 0.60, 0.18)
const OPPONENT_COLOR: Color = Color("#174A9A")
const PLAYER_COLOR: Color = Color(0.09, 0.29, 0.60, 0.35)
const SELECTED_FILL: Color = Color(0.90, 0.55, 0.10, 0.16)
const SELECTED_LINE: Color = Color(0.90, 0.55, 0.10, 0.9)
const RULER_FILL: Color = Color(0.09, 0.29, 0.60, 0.10)
const PLAYHEAD_COLOR: Color = Color(0.85, 0.2, 0.2, 0.9)
const FIRE_COLOR: Color = Color(0.92, 0.30, 0.10, 1.0)
const ICE_COLOR: Color = Color(0.45, 0.80, 0.96, 1.0)
const LEAF_COLOR: Color = Color(0.85, 0.48, 0.10, 1.0)
const FLOWER_COLOR: Color = Color(0.93, 0.45, 0.62, 1.0)

const BEATS_PER_BAR: int = 4

const LANE_Y_OPP: Array[float] = [63.0, 113.0, 163.0, 213.0]
const LANE_Y_PLAYER: Array[float] = [308.0, 358.0, 408.0, 458.0]
const EVENT_Y0: float = 240.0
const EVENT_Y1: float = 284.0

const LEFT_MARGIN: float = 70.0
const RULER_Y1: float = 32.0
const LANE_CLICK_RADIUS: float = 22.0
const MIN_BEATS_VISIBLE: float = 48.0
const TAIL_BEATS: float = 8.0

var editor: Control
var px_per_beat: float = 90.0

# Estado do arrasto do mouse.
var drag_active: bool = false
var drag_kind: String = ""        # "lane" ou "event"
var drag_lane: int = 0
var drag_start_raw: float = 0.0
var drag_end_raw: float = 0.0
var drag_erase: bool = false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    custom_minimum_size.y = 500.0

func _process(_delta: float) -> void:
    _update_size()
    queue_redraw()

func set_zoom(new_value: float) -> void:
    px_per_beat = clampf(new_value, 30.0, 300.0)
    _update_size()
    queue_redraw()

func _update_size() -> void:
    # A timeline representa a música inteira mesmo antes de existirem frases.
    var last_beat: float = MIN_BEATS_VISIBLE

    if editor != null:
        last_beat = maxf(last_beat, editor.get_song_length_beats())
        var response_delay: float = float(editor.response_spin.value)
        for raw_phrase in (editor.phrases as Array):
            if not (raw_phrase is Dictionary):
                continue
            var phrase: Dictionary = raw_phrase as Dictionary
            var end_beat: float = float(phrase.get("end_beat", 0.0)) + response_delay
            last_beat = maxf(last_beat, end_beat)

    custom_minimum_size.x = LEFT_MARGIN + (last_beat + TAIL_BEATS) * px_per_beat

# --- Mouse ---------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
    if editor == null:
        return

    if event is InputEventMouseButton:
        var mb: InputEventMouseButton = event as InputEventMouseButton
        # Outros botões (roda do mouse) seguem pro ScrollContainer.
        if mb.button_index != MOUSE_BUTTON_LEFT:
            return
        if mb.pressed:
            _on_press(mb.position)
        else:
            _on_release(mb.position)
        accept_event()
    elif event is InputEventMouseMotion and drag_active:
        var mm: InputEventMouseMotion = event as InputEventMouseMotion
        drag_end_raw = _x_to_beat(mm.position.x)
        accept_event()

func _on_press(pos: Vector2) -> void:
    var beat_raw: float = _x_to_beat(pos.x)

    if pos.y <= RULER_Y1:
        editor.on_ruler_clicked(maxf(beat_raw, 0.0))
        return

    for i in range(4):
        if absf(pos.y - LANE_Y_OPP[i]) <= LANE_CLICK_RADIUS:
            drag_active = true
            drag_kind = "lane"
            drag_lane = i
            drag_start_raw = beat_raw
            drag_end_raw = beat_raw
            drag_erase = editor.lane_press_is_erase(i, beat_raw)
            return

    if editor.events_enabled and editor.current_tool == "flower" and pos.y >= EVENT_Y0 and pos.y <= EVENT_Y1:
        drag_active = true
        drag_kind = "event"
        drag_start_raw = beat_raw
        drag_end_raw = beat_raw
        drag_erase = editor.event_press_is_erase(beat_raw)

func _on_release(pos: Vector2) -> void:
    if not drag_active:
        return
    drag_active = false
    var end_raw: float = _x_to_beat(pos.x)
    if drag_kind == "lane":
        editor.on_lane_released(drag_lane, drag_start_raw, end_raw)
    elif drag_kind == "event":
        editor.on_event_released(drag_start_raw, end_raw)

func _x_to_beat(x: float) -> float:
    return (x - LEFT_MARGIN) / px_per_beat

func _beat_to_x(beat: float) -> float:
    return LEFT_MARGIN + beat * px_per_beat

# --- Desenho -------------------------------------------------------------------

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.98, 0.97, 0.94, 0.90), true)
    draw_rect(Rect2(0.0, 0.0, size.x, RULER_Y1), RULER_FILL, true)

    draw_string(ThemeDB.fallback_font, Vector2(LEFT_MARGIN, 50.0), "LORDE — clique: nota | arraste: nota longa | clique numa nota: apagar", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
    draw_string(ThemeDB.fallback_font, Vector2(LEFT_MARGIN, 296.0), "RESPOSTA DO PLAYER (gerada automaticamente pelo atraso, somente leitura)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(INK.r, INK.g, INK.b, 0.6))

    for i in range(4):
        _draw_lane_label(i, LANE_Y_OPP[i], 1.0)
        _draw_lane_label(i, LANE_Y_PLAYER[i], 0.5)
        draw_line(Vector2(LEFT_MARGIN, LANE_Y_OPP[i]), Vector2(size.x, LANE_Y_OPP[i]), GRID, 2.0, true)
        draw_line(Vector2(LEFT_MARGIN, LANE_Y_PLAYER[i]), Vector2(size.x, LANE_Y_PLAYER[i]), GRID, 1.0, true)

    _draw_timeline_grid()

    if editor == null:
        return

    var song_end_beat: float = editor.get_song_length_beats()
    if song_end_beat > 0.0:
        var song_end_x: float = _beat_to_x(song_end_beat)
        draw_line(Vector2(song_end_x, RULER_Y1), Vector2(song_end_x, size.y), PLAYHEAD_COLOR, 2.0, true)
        draw_string(ThemeDB.fallback_font, Vector2(song_end_x + 4.0, 22.0), "FIM", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, PLAYHEAD_COLOR)

    if editor.events_enabled:
        _draw_event_strip()

    var data: Array = editor.phrases as Array
    var response_delay: float = float(editor.response_spin.value)
    var selected_index: int = editor.selected_phrase_index

    for i in range(data.size()):
        var raw_phrase: Variant = data[i]
        if not (raw_phrase is Dictionary):
            continue
        var phrase: Dictionary = raw_phrase as Dictionary
        var is_selected: bool = i == selected_index
        var start_beat: float = float(phrase.get("start_beat", 0.0))
        var end_beat: float = float(phrase.get("end_beat", start_beat + 1.0))

        _draw_phrase_band(start_beat, end_beat, RULER_Y1 + 4.0, 236.0, is_selected)
        _draw_phrase_band(start_beat + response_delay, end_beat + response_delay, 300.0, 480.0, false)

        var notes: Array = phrase.get("notes", []) as Array
        for raw_note in notes:
            if not (raw_note is Dictionary):
                continue
            var note: Dictionary = raw_note as Dictionary
            var beat: float = float(note.get("beat", 0.0))
            var lane: int = int(note.get("lane", 0))
            if lane < 0 or lane >= 4:
                continue
            var type_name: String = str(note.get("type", "normal"))
            var duration: float = float(note.get("duration", 0.0))
            var base_color: Color = SELECTED_LINE if is_selected else OPPONENT_COLOR

            var opponent_pos: Vector2 = Vector2(_beat_to_x(beat), LANE_Y_OPP[lane])
            var player_pos: Vector2 = Vector2(_beat_to_x(beat + response_delay), LANE_Y_PLAYER[lane])

            if duration > 0.0:
                var tail_w: float = duration * px_per_beat
                draw_rect(Rect2(opponent_pos.x, opponent_pos.y - 7.0, tail_w, 14.0), Color(base_color.r, base_color.g, base_color.b, 0.45), true)
                draw_rect(Rect2(opponent_pos.x, opponent_pos.y - 7.0, tail_w, 14.0), base_color, false, 2.0)
                draw_rect(Rect2(player_pos.x, player_pos.y - 5.0, tail_w, 10.0), PLAYER_COLOR, true)

            draw_line(opponent_pos + Vector2(0.0, 14.0), player_pos + Vector2(0.0, -12.0), PLAYER_COLOR, 1.5, true)
            _draw_marker(opponent_pos, type_name, 12.0, base_color)
            _draw_marker(player_pos, type_name, 9.0, PLAYER_COLOR)

    _draw_drag_preview()

    var cursor_x: float = _beat_to_x(Conductor.get_current_beat())
    draw_line(Vector2(cursor_x, 0.0), Vector2(cursor_x, size.y), PLAYHEAD_COLOR, 2.0, true)

func _draw_lane_label(lane: int, y: float, alpha: float) -> void:
    var color: Color = Color(INK.r, INK.g, INK.b, alpha)
    draw_string(ThemeDB.fallback_font, Vector2(6.0, y + 7.0), str(Lanes.LETTERS[lane]), HORIZONTAL_ALIGNMENT_LEFT, 30, 20, color)
    draw_polyline(Lanes.arrow_outline(lane, Vector2(46.0, y), 9.0), color, 2.0, true)

func _draw_marker(pos: Vector2, type_name: String, radius: float, base: Color) -> void:
    match type_name:
        "fire":
            draw_circle(pos, radius, FIRE_COLOR)
            var flame: PackedVector2Array = PackedVector2Array([
                pos + Vector2(0.0, -radius * 0.8),
                pos + Vector2(radius * 0.55, radius * 0.5),
                pos + Vector2(-radius * 0.55, radius * 0.5)
            ])
            draw_colored_polygon(flame, Color(1.0, 0.9, 0.4, 0.95))
        "ice":
            draw_circle(pos, radius, ICE_COLOR)
            for k in range(3):
                var a: float = (PI / 3.0) * float(k)
                var d: Vector2 = Vector2(cos(a), sin(a)) * radius * 0.8
                draw_line(pos - d, pos + d, Color(0.1, 0.35, 0.58, 0.95), 1.5, true)
        "leaf":
            draw_circle(pos, radius, LEAF_COLOR)
            draw_line(pos + Vector2(-radius * 0.6, radius * 0.4), pos + Vector2(radius * 0.6, -radius * 0.4), Color(0.42, 0.20, 0.05, 0.95), 2.0, true)
        _:
            draw_circle(pos, radius, base)

func _draw_event_strip() -> void:
    draw_rect(Rect2(LEFT_MARGIN, EVENT_Y0, size.x - LEFT_MARGIN, EVENT_Y1 - EVENT_Y0), Color(FLOWER_COLOR.r, FLOWER_COLOR.g, FLOWER_COLOR.b, 0.08), true)
    draw_rect(Rect2(LEFT_MARGIN, EVENT_Y0, size.x - LEFT_MARGIN, EVENT_Y1 - EVENT_Y0), Color(FLOWER_COLOR.r, FLOWER_COLOR.g, FLOWER_COLOR.b, 0.5), false, 1.5)
    draw_string(ThemeDB.fallback_font, Vector2(4.0, (EVENT_Y0 + EVENT_Y1) * 0.5 + 5.0), "FLORES", HORIZONTAL_ALIGNMENT_LEFT, 64, 13, FLOWER_COLOR.darkened(0.2))

    for raw in (editor.events as Array):
        if not (raw is Dictionary):
            continue
        var ev: Dictionary = raw as Dictionary
        if str(ev.get("type", "")) != "flower":
            continue
        var x0: float = _beat_to_x(float(ev.get("start_beat", 0.0)))
        var x1: float = _beat_to_x(float(ev.get("end_beat", 0.0)))
        var rect: Rect2 = Rect2(x0, EVENT_Y0 + 4.0, maxf(x1 - x0, 6.0), EVENT_Y1 - EVENT_Y0 - 8.0)
        draw_rect(rect, Color(FLOWER_COLOR.r, FLOWER_COLOR.g, FLOWER_COLOR.b, 0.55), true)
        draw_rect(rect, FLOWER_COLOR.darkened(0.3), false, 2.0)

        var half_text: String = "CIMA" if str(ev.get("half", "top")) == "top" else "BAIXO"
        var field_text: String = str(ev.get("field", "both")).to_upper()
        if field_text == "BOTH":
            field_text = "AMBOS"
        draw_string(ThemeDB.fallback_font, Vector2(x0 + 4.0, EVENT_Y0 + 25.0), "%s · %s" % [half_text, field_text], HORIZONTAL_ALIGNMENT_LEFT, int(maxf(x1 - x0 - 6.0, 10.0)), 12, Color(0.35, 0.08, 0.2, 1.0))

        # Sombra rosada nas lanes que a flor cobre (Lorde / Player).
        var first: int = 0 if str(ev.get("half", "top")) == "top" else 2
        var field: String = str(ev.get("field", "both"))
        var cover: Color = Color(FLOWER_COLOR.r, FLOWER_COLOR.g, FLOWER_COLOR.b, 0.20)
        if field == "both" or field == "lorde":
            draw_rect(Rect2(x0, LANE_Y_OPP[first] - 22.0, maxf(x1 - x0, 6.0), LANE_Y_OPP[first + 1] - LANE_Y_OPP[first] + 44.0), cover, true)
        if field == "both" or field == "player":
            draw_rect(Rect2(x0, LANE_Y_PLAYER[first] - 22.0, maxf(x1 - x0, 6.0), LANE_Y_PLAYER[first + 1] - LANE_Y_PLAYER[first] + 44.0), cover, true)

func _draw_drag_preview() -> void:
    if not drag_active or editor == null:
        return
    var start_beat: float = editor.snap_beat(drag_start_raw)
    var end_beat: float = editor.snap_beat(drag_end_raw)

    if drag_kind == "lane":
        var y: float = LANE_Y_OPP[drag_lane]
        var pos: Vector2 = Vector2(_beat_to_x(start_beat), y)
        if drag_erase:
            draw_arc(pos, 16.0, 0.0, TAU, 24, Color(0.85, 0.15, 0.15, 0.9), 3.0, true)
            draw_line(pos + Vector2(-10.0, -10.0), pos + Vector2(10.0, 10.0), Color(0.85, 0.15, 0.15, 0.9), 3.0, true)
            draw_line(pos + Vector2(-10.0, 10.0), pos + Vector2(10.0, -10.0), Color(0.85, 0.15, 0.15, 0.9), 3.0, true)
            return
        var snap_value: float = maxf(float(editor.snap_spin.value), 0.0625)
        if editor.current_tool == "normal" and end_beat - start_beat >= snap_value * 0.999:
            var tail_w: float = (end_beat - start_beat) * px_per_beat
            draw_rect(Rect2(pos.x, y - 7.0, tail_w, 14.0), Color(SELECTED_LINE.r, SELECTED_LINE.g, SELECTED_LINE.b, 0.45), true)
            draw_rect(Rect2(pos.x, y - 7.0, tail_w, 14.0), SELECTED_LINE, false, 2.0)
        var ghost_type: String = editor.current_tool if editor.current_tool != "flower" else "normal"
        _draw_marker(pos, ghost_type, 12.0, Color(SELECTED_LINE.r, SELECTED_LINE.g, SELECTED_LINE.b, 0.6))
    elif drag_kind == "event":
        var x0: float = _beat_to_x(start_beat)
        var x1: float = _beat_to_x(maxf(end_beat, start_beat))
        var color: Color = Color(0.85, 0.15, 0.15, 0.5) if drag_erase else Color(FLOWER_COLOR.r, FLOWER_COLOR.g, FLOWER_COLOR.b, 0.45)
        draw_rect(Rect2(x0, EVENT_Y0 + 4.0, maxf(x1 - x0, 8.0), EVENT_Y1 - EVENT_Y0 - 8.0), color, true)

func _draw_timeline_grid() -> void:
    var total_beats: int = int(ceil((size.x - LEFT_MARGIN) / px_per_beat)) + 1
    var snap_value: float = 0.25
    if editor != null:
        snap_value = maxf(float(editor.snap_spin.value), 0.0625)

    # Subdivisões: com SNAP=0.25, uma linha a cada 1/4 de beat.
    var subdivision: float = minf(snap_value, 0.25)
    var total_steps: int = int(ceil(float(total_beats) / subdivision)) + 1

    for step_i in range(total_steps):
        var beat: float = float(step_i) * subdivision
        var x: float = _beat_to_x(beat)
        if x > size.x + 1.0:
            break

        var is_bar: bool = absf(fmod(beat, float(BEATS_PER_BAR))) < 0.001
        var is_beat: bool = absf(fmod(beat, 1.0)) < 0.001

        var line_color: Color = GRID_SUB
        var line_width: float = 1.0
        if is_bar:
            line_color = GRID_BAR
            line_width = 2.5
        elif is_beat:
            line_color = GRID_BEAT
            line_width = 1.5

        draw_line(Vector2(x, RULER_Y1), Vector2(x, size.y), line_color, line_width, true)

        if is_bar:
            var bar_number: int = int(round(beat / BEATS_PER_BAR)) + 1
            draw_string(ThemeDB.fallback_font, Vector2(x + 4.0, 22.0), str(bar_number), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, INK)
        elif is_beat:
            var beat_in_bar: int = int(round(fmod(beat, float(BEATS_PER_BAR)))) + 1
            draw_string(ThemeDB.fallback_font, Vector2(x + 3.0, 15.0), str(beat_in_bar), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(INK.r, INK.g, INK.b, 0.55))

func _draw_phrase_band(start_beat: float, end_beat: float, top: float, bottom: float, is_selected: bool) -> void:
    var x_start: float = _beat_to_x(start_beat)
    var x_end: float = _beat_to_x(maxf(end_beat, start_beat + 0.25))
    var rect: Rect2 = Rect2(x_start, top, maxf(x_end - x_start, 10.0), bottom - top)
    var fill: Color = SELECTED_FILL if is_selected else Color(OPPONENT_COLOR.r, OPPONENT_COLOR.g, OPPONENT_COLOR.b, 0.05)
    var line_color: Color = SELECTED_LINE if is_selected else OPPONENT_COLOR
    draw_rect(rect, fill, true)
    draw_line(Vector2(x_start, top), Vector2(x_start, bottom), line_color, 2.0, true)
    draw_line(Vector2(x_end, top), Vector2(x_end, bottom), line_color, 2.0, true)

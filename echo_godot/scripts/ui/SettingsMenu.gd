extends Control

# Tela de configurações: volume da música, volume dos efeitos, ajuste de
# sincronia e tela cheia. Tudo é salvo automaticamente (user://settings.cfg).
# UI montada por código, no mesmo estilo papel/tinta do resto do jogo.

const MAIN_SCENE: String = "res://scenes/Main.tscn"

const INK: Color = Color(0.0902, 0.2902, 0.6039, 1.0)
const PAPER: Color = Color(0.98, 0.97, 0.94, 0.96)
const HIGHLIGHT: Color = Color(0.85, 0.55, 0.12, 1.0)

const PANEL_X: float = 270.0
const PANEL_Y: float = 130.0
const PANEL_W: float = 740.0
const PANEL_H: float = 450.0

var music_slider: HSlider
var music_value: Label
var sfx_slider: HSlider
var sfx_value: Label
var sync_slider: HSlider
var sync_value: Label
var fullscreen_check: CheckButton
var first_focus: Control = null

func _ready() -> void:
    Conductor.stop()
    MenuMusic.start()
    _build()
    if first_focus != null:
        first_focus.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_ESCAPE:
            _go_back()

func _build() -> void:
    var title: Label = Label.new()
    title.text = "CONFIGURAÇÕES"
    title.position = Vector2(0.0, 40.0)
    title.size = Vector2(1280.0, 60.0)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 44)
    title.add_theme_color_override("font_color", INK)
    add_child(title)

    var panel: Panel = Panel.new()
    panel.position = Vector2(PANEL_X, PANEL_Y)
    panel.size = Vector2(PANEL_W, PANEL_H)
    panel.add_theme_stylebox_override("panel", _box(PAPER, INK, 4, 12, true))
    add_child(panel)

    # --- Música ---
    music_slider = _make_slider(0.0, 100.0, 1.0, GameSettings.music_volume * 100.0)
    music_value = _row(panel, "MÚSICA", 36.0, music_slider)
    music_slider.value_changed.connect(_on_music_changed)
    music_slider.drag_ended.connect(_on_slider_drag_ended)
    _on_music_changed(music_slider.value)

    # --- Efeitos ---
    sfx_slider = _make_slider(0.0, 100.0, 1.0, GameSettings.sfx_volume * 100.0)
    sfx_value = _row(panel, "EFEITOS SONOROS", 104.0, sfx_slider)
    sfx_slider.value_changed.connect(_on_sfx_changed)
    sfx_slider.drag_ended.connect(_on_sfx_drag_ended)
    _on_sfx_changed(sfx_slider.value)

    # --- Sincronia ---
    sync_slider = _make_slider(-150.0, 150.0, 5.0, GameSettings.sync_offset_ms)
    sync_value = _row(panel, "SINCRONIA", 172.0, sync_slider)
    sync_slider.value_changed.connect(_on_sync_changed)
    sync_slider.drag_ended.connect(_on_slider_drag_ended)
    _on_sync_changed(sync_slider.value)

    var sync_hint: Label = Label.new()
    sync_hint.text = "Se as notas chegam DEPOIS do som, aumente (+). Se chegam ANTES, diminua (−)."
    sync_hint.position = Vector2(36.0, 214.0)
    sync_hint.size = Vector2(PANEL_W - 72.0, 24.0)
    sync_hint.add_theme_font_size_override("font_size", 13)
    sync_hint.add_theme_color_override("font_color", Color(INK.r, INK.g, INK.b, 0.7))
    panel.add_child(sync_hint)

    # --- Tela cheia ---
    var full_label: Label = Label.new()
    full_label.text = "TELA CHEIA"
    full_label.position = Vector2(36.0, 262.0)
    full_label.size = Vector2(200.0, 30.0)
    full_label.add_theme_font_size_override("font_size", 20)
    full_label.add_theme_color_override("font_color", INK)
    panel.add_child(full_label)

    fullscreen_check = CheckButton.new()
    fullscreen_check.position = Vector2(300.0, 256.0)
    fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
    fullscreen_check.add_theme_color_override("font_color", INK)
    fullscreen_check.toggled.connect(_on_fullscreen_toggled)
    panel.add_child(fullscreen_check)

    var f11: Label = Label.new()
    f11.text = "(F11 alterna em qualquer tela)"
    f11.position = Vector2(390.0, 266.0)
    f11.size = Vector2(300.0, 24.0)
    f11.add_theme_font_size_override("font_size", 13)
    f11.add_theme_color_override("font_color", Color(INK.r, INK.g, INK.b, 0.7))
    panel.add_child(f11)

    # --- Botões ---
    var reset: Button = Button.new()
    reset.text = "RESTAURAR PADRÕES"
    reset.position = Vector2(36.0, PANEL_H - 80.0)
    reset.size = Vector2(250.0, 46.0)
    _style_button(reset, INK)
    reset.pressed.connect(_on_reset_pressed)
    panel.add_child(reset)

    var back: Button = Button.new()
    back.text = "VOLTAR"
    back.position = Vector2(PANEL_W - 36.0 - 200.0, PANEL_H - 80.0)
    back.size = Vector2(200.0, 46.0)
    _style_button(back, HIGHLIGHT)
    back.pressed.connect(_go_back)
    panel.add_child(back)

    first_focus = music_slider

# --- Montagem de linhas ----------------------------------------------------------

func _row(panel: Panel, label_text: String, y: float, slider: HSlider) -> Label:
    var label: Label = Label.new()
    label.text = label_text
    label.position = Vector2(36.0, y)
    label.size = Vector2(250.0, 30.0)
    label.add_theme_font_size_override("font_size", 20)
    label.add_theme_color_override("font_color", INK)
    panel.add_child(label)

    slider.position = Vector2(300.0, y + 4.0)
    slider.size = Vector2(300.0, 24.0)
    panel.add_child(slider)

    var value_label: Label = Label.new()
    value_label.position = Vector2(620.0, y)
    value_label.size = Vector2(100.0, 30.0)
    value_label.add_theme_font_size_override("font_size", 20)
    value_label.add_theme_color_override("font_color", HIGHLIGHT)
    panel.add_child(value_label)
    return value_label

func _make_slider(min_value: float, max_value: float, step: float, start: float) -> HSlider:
    var slider: HSlider = HSlider.new()
    slider.min_value = min_value
    slider.max_value = max_value
    slider.step = step
    slider.value = start
    slider.focus_mode = Control.FOCUS_ALL
    var track: StyleBoxFlat = _box(Color(0.90, 0.89, 0.86, 1.0), INK, 2, 4)
    track.content_margin_top = 4.0
    track.content_margin_bottom = 4.0
    var filled: StyleBoxFlat = _box(INK, INK, 2, 4)
    filled.content_margin_top = 4.0
    filled.content_margin_bottom = 4.0
    slider.add_theme_stylebox_override("slider", track)
    slider.add_theme_stylebox_override("grabber_area", filled)
    slider.add_theme_stylebox_override("grabber_area_highlight", filled)
    return slider

# --- Callbacks ---------------------------------------------------------------------

func _on_music_changed(value: float) -> void:
    GameSettings.set_music_volume(value / 100.0)
    music_value.text = "%d%%" % int(value)

func _on_sfx_changed(value: float) -> void:
    GameSettings.set_sfx_volume(value / 100.0)
    sfx_value.text = "%d%%" % int(value)

func _on_sync_changed(value: float) -> void:
    GameSettings.sync_offset_ms = value
    sync_value.text = "%+d ms" % int(value)

func _on_slider_drag_ended(_changed: bool) -> void:
    GameSettings.save_settings()

func _on_sfx_drag_ended(_changed: bool) -> void:
    # Toca um som pra você ouvir o novo volume dos efeitos.
    Sfx.play("ui_click")
    GameSettings.save_settings()

func _on_fullscreen_toggled(pressed: bool) -> void:
    GameSettings.set_fullscreen(pressed)
    GameSettings.save_settings()

func _on_reset_pressed() -> void:
    GameSettings.reset_defaults()
    music_slider.value = GameSettings.music_volume * 100.0
    sfx_slider.value = GameSettings.sfx_volume * 100.0
    sync_slider.value = GameSettings.sync_offset_ms

func _go_back() -> void:
    GameSettings.save_settings()
    get_tree().change_scene_to_file(MAIN_SCENE)

# --- Helpers de UI ---------------------------------------------------------------------

func _box(bg: Color, border: Color, border_width: int, radius: int, shadow: bool = false) -> StyleBoxFlat:
    var box: StyleBoxFlat = StyleBoxFlat.new()
    box.bg_color = bg
    box.border_color = border
    box.set_border_width_all(border_width)
    box.set_corner_radius_all(radius)
    if shadow:
        box.shadow_color = Color(INK.r, INK.g, INK.b, 0.16)
        box.shadow_size = 8
    return box

func _style_button(button: Button, accent: Color) -> void:
    button.add_theme_stylebox_override("normal", _box(PAPER, accent, 2, 6))
    button.add_theme_stylebox_override("hover", _box(Color(0.90, 0.93, 0.98, 1.0), accent, 3, 6))
    button.add_theme_stylebox_override("pressed", _box(accent, accent, 2, 6))
    button.add_theme_stylebox_override("focus", _box(Color(0.90, 0.93, 0.98, 1.0), HIGHLIGHT, 4, 6))
    button.add_theme_color_override("font_color", INK)
    button.add_theme_color_override("font_hover_color", INK)
    button.add_theme_color_override("font_pressed_color", Color.WHITE)
    button.add_theme_color_override("font_focus_color", INK)
    button.add_theme_font_size_override("font_size", 18)

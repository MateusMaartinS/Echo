extends CanvasLayer
class_name PauseMenu

# Overlay de pausa da partida (criado por código pelo Battle).
#   show_pause()/hide_pause()  -> menu com CONTINUAR / REINICIAR / FASES
#   show_count(n)/hide_count() -> número grande da contagem "1, 2, 3, 4"
# Quem decide o que fazer (pausar, contar, retomar) é o Battle.

signal resume_pressed
signal restart_pressed
signal quit_pressed

const INK: Color = Color(0.0902, 0.2902, 0.6039, 1.0)
const PAPER: Color = Color(0.98, 0.97, 0.94, 0.97)
const HIGHLIGHT: Color = Color(0.85, 0.55, 0.12, 1.0)

var dim: ColorRect
var panel: Panel
var resume_button: Button
var count_label: Label

func _ready() -> void:
    layer = 20
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build()
    hide_pause()
    hide_count()

func is_open() -> bool:
    return panel != null and panel.visible

func back_to_pause() -> bool:
    return false

func show_pause() -> void:
    hide_count()
    dim.visible = true
    panel.visible = true
    # Evita tocar o som de "hover" só porque o foco foi pro botão.
    resume_button.set_meta("sfx_added_ms", Time.get_ticks_msec())
    resume_button.grab_focus()

func hide_pause() -> void:
    dim.visible = false
    panel.visible = false

func show_count(number: int) -> void:
    count_label.text = "VAI!" if number == 4 else str(number)
    count_label.visible = true
    count_label.pivot_offset = count_label.size * 0.5
    count_label.scale = Vector2(1.4, 1.4)
    var tween: Tween = create_tween()
    tween.tween_property(count_label, "scale", Vector2(1.0, 1.0), 0.22)

func hide_count() -> void:
    count_label.visible = false

func _build() -> void:
    dim = ColorRect.new()
    dim.color = Color(0.96, 0.945, 0.91, 0.78)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.mouse_filter = Control.MOUSE_FILTER_STOP   # bloqueia cliques na tela atrás
    add_child(dim)

    panel = Panel.new()
    panel.size = Vector2(440.0, 340.0)
    panel.position = Vector2((1280.0 - 440.0) * 0.5, (720.0 - 340.0) * 0.5)
    panel.add_theme_stylebox_override("panel", _box(PAPER, INK, 4, 12, true))
    add_child(panel)

    var title: Label = Label.new()
    title.text = "PAUSADO"
    title.position = Vector2(0.0, 22.0)
    title.size = Vector2(440.0, 56.0)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 42)
    title.add_theme_color_override("font_color", INK)
    panel.add_child(title)

    var note: Label = Label.new()
    note.text = "Ao continuar, contagem de 4 tempos antes da música voltar"
    note.position = Vector2(20.0, 80.0)
    note.size = Vector2(400.0, 22.0)
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 13)
    note.add_theme_color_override("font_color", Color(INK.r, INK.g, INK.b, 0.75))
    panel.add_child(note)

    resume_button = _button("CONTINUAR", 118.0, HIGHLIGHT)
    resume_button.pressed.connect(func() -> void: resume_pressed.emit())
    var restart: Button = _button("REINICIAR", 182.0, INK)
    restart.pressed.connect(func() -> void: restart_pressed.emit())
    var quit: Button = _button("SAIR PARA AS FASES", 246.0, INK)
    quit.pressed.connect(func() -> void: quit_pressed.emit())

    count_label = Label.new()
    count_label.position = Vector2(0.0, 190.0)
    count_label.size = Vector2(1280.0, 300.0)
    count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    count_label.add_theme_font_size_override("font_size", 190)
    count_label.add_theme_color_override("font_color", HIGHLIGHT)
    count_label.add_theme_color_override("font_outline_color", Color(0.98, 0.97, 0.94, 1.0))
    count_label.add_theme_constant_override("outline_size", 16)
    count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(count_label)

func _button(text_value: String, y: float, accent: Color) -> Button:
    var button: Button = Button.new()
    button.text = text_value
    button.position = Vector2(60.0, y)
    button.size = Vector2(320.0, 52.0)
    button.add_theme_stylebox_override("normal", _box(PAPER, accent, 2, 8))
    button.add_theme_stylebox_override("hover", _box(Color(0.90, 0.93, 0.98, 1.0), accent, 3, 8))
    button.add_theme_stylebox_override("pressed", _box(accent, accent, 2, 8))
    button.add_theme_stylebox_override("focus", _box(Color(0.90, 0.93, 0.98, 1.0), HIGHLIGHT, 4, 8))
    button.add_theme_color_override("font_color", INK)
    button.add_theme_color_override("font_hover_color", INK)
    button.add_theme_color_override("font_pressed_color", Color.WHITE)
    button.add_theme_color_override("font_focus_color", INK)
    button.add_theme_font_size_override("font_size", 20)
    panel.add_child(button)
    return button

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

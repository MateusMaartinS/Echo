extends RefCounted
class_name SeasonMenuStyle

const INK := Color("#35483e")
const PAPER := Color("#faf3e4")
const MUTED := Color("#6c7767")
const ACCENTS := {"spring": Color("#9d526d"), "summer": Color("#986421"), "autumn": Color("#975637"), "winter": Color("#4f7589"), "tutorial": Color("#527357")}

static func box(bg: Color, border: Color, width: int = 1, radius: int = 5, shadow: bool = false) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(radius)
    if shadow:
        style.shadow_color = Color(.20,.24,.17,.16)
        style.shadow_size = 7
        style.shadow_offset = Vector2(2,4)
    return style

static func button(control: Button, accent: Color, primary: bool = false) -> void:
    control.add_theme_stylebox_override("normal", box(accent if primary else PAPER, accent, 1, 5, primary))
    control.add_theme_stylebox_override("hover", box(accent.lightened(.08) if primary else PAPER.darkened(.045), accent, 2))
    control.add_theme_stylebox_override("pressed", box(accent.darkened(.15), accent, 2))
    var focus := box(Color(0,0,0,0), Color("#d4a653"), 3, 5)
    focus.expand_margin_left = 3
    focus.expand_margin_top = 3
    focus.expand_margin_right = 3
    focus.expand_margin_bottom = 3
    control.add_theme_stylebox_override("focus", focus)
    control.add_theme_stylebox_override("disabled", box(Color("#e1dcca"), Color("#b5b8a4"), 1))
    control.add_theme_color_override("font_color", PAPER if primary else accent)
    control.add_theme_color_override("font_hover_color", PAPER if primary else accent)
    control.add_theme_color_override("font_pressed_color", PAPER)
    control.add_theme_color_override("font_focus_color", PAPER if primary else accent)
    control.add_theme_color_override("font_disabled_color", Color("#747d6d"))
    control.add_theme_font_size_override("font_size", 18)

static func label(text: String, pos: Vector2, dimensions: Vector2, font_size: int, color: Color = INK, centered: bool = false, wrapped: bool = false) -> Label:
    var control := Label.new()
    control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrapped else TextServer.AUTOWRAP_OFF
    control.clip_text = true
    control.text = text
    control.position = pos
    control.size = dimensions
    control.mouse_filter = Control.MOUSE_FILTER_IGNORE
    control.add_theme_font_size_override("font_size", font_size)
    control.add_theme_color_override("font_color", color)
    if centered:
        control.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return control

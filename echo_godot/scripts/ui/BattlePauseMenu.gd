extends PauseMenu
class_name BattlePauseMenu

var title_label: Label
var note_label: Label
var controls_label: Label
var controls_button: Button
var main_buttons: Array[Button] = []
var controls_open: bool = false

func _build() -> void:
    dim=ColorRect.new()
    dim.color=Color(.035,.02,.07,.86)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dim.mouse_filter=Control.MOUSE_FILTER_STOP
    add_child(dim)
    panel=Panel.new()
    panel.position=Vector2(370,110)
    panel.size=Vector2(540,500)
    panel.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    panel.add_theme_stylebox_override("panel",BattleHudStyle.box(Color("#211a31"),BattleHudStyle.GOLD,3))
    add_child(panel)
    title_label=_label("PAUSA",Vector2(30,22),Vector2(480,44),30)
    note_label=_label("1, 2, 3, VAI!\nA MÚSICA VOLTA NO QUARTO TEMPO",Vector2(30,76),Vector2(480,50),20)
    resume_button=_pixel_button("CONTINUAR",138)
    resume_button.pressed.connect(func() -> void: resume_pressed.emit())
    var restart: Button = _pixel_button("REINICIAR",202)
    restart.pressed.connect(func() -> void: restart_pressed.emit())
    controls_button=_pixel_button("CONTROLES",266)
    controls_button.pressed.connect(_toggle_controls)
    var quit: Button = _pixel_button("SAIR PARA AS FASES",330)
    quit.pressed.connect(func() -> void: quit_pressed.emit())
    main_buttons=[resume_button,restart,quit]
    controls_label=_label("CIMA       D / ↑\nDIREITA    F / →\nESQUERDA   J / ←\nBAIXO      K / ↓\n\nSEGURE NAS NOTAS LONGAS\nR: REINICIAR    ESC: PAUSAR\nF11: TELA CHEIA",Vector2(40,112),Vector2(460,280),20)
    controls_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
    controls_label.hide()
    count_label=Label.new()
    count_label.position=Vector2(0,260)
    count_label.size=Vector2(1280,180)
    count_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    count_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
    count_label.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    count_label.add_theme_font_override("font",BattleHudStyle.FONT)
    count_label.add_theme_font_size_override("font_size",100)
    count_label.add_theme_color_override("font_color",BattleHudStyle.GOLD)
    count_label.add_theme_color_override("font_outline_color",BattleHudStyle.INK)
    count_label.add_theme_constant_override("outline_size",8)
    count_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(count_label)

func _label(text_value: String, at: Vector2, dimensions: Vector2, font_size: int) -> Label:
    var label := Label.new()
    label.text=text_value
    label.position=at
    label.size=dimensions
    label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_override("font",BattleHudStyle.FONT)
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",BattleHudStyle.CREAM)
    panel.add_child(label)
    return label

func _pixel_button(text_value: String, y: float) -> Button:
    var button := Button.new()
    button.text=text_value
    button.position=Vector2(60,y)
    button.size=Vector2(420,50)
    BattleHudStyle.style_button(button)
    panel.add_child(button)
    return button

func show_pause() -> void:
    _set_controls(false)
    super.show_pause()

func show_count(number: int) -> void:
    count_label.text="VAI!" if number==4 else str(number)
    count_label.scale=Vector2.ONE
    count_label.show()

func _toggle_controls() -> void:
    _set_controls(not controls_open)
    controls_button.grab_focus()

func _set_controls(value: bool) -> void:
    controls_open=value
    controls_label.visible=value
    note_label.visible=not value
    title_label.text="CONTROLES" if value else "PAUSA"
    controls_button.text="VOLTAR" if value else "CONTROLES"
    controls_button.position.y=418 if value else 266
    for button in main_buttons:
        button.visible=not value

func back_to_pause() -> bool:
    if not controls_open:
        return false
    _set_controls(false)
    resume_button.grab_focus()
    return true

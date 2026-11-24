extends Control
class_name EchoLevelSelect

# Same stage availability, records and editor routing; pixel presentation.
const MAIN_SCENE: String = "res://scenes/Main.tscn"
const BATTLE_SCENE: String = "res://scenes/Battle.tscn"
const EDITOR_SCENE: String = "res://scenes/Editor.tscn"
const INK: Color = BattleHudStyle.CREAM
const PAPER: Color = Color("#211a31")
const HIGHLIGHT: Color = BattleHudStyle.GOLD
const CARD_MAX_W: float = 285.0
const CARD_H: float = 512.0
const CARD_GAP: float = 16.0
const SIDE_MARGIN: float = 34.0
const CARD_Y: float = 148.0
const ACCENTS := {"tutorial":Color("#a4bea0"),"spring":Color("#e3aec4"),"autumn":Color("#dba67c"),"summer":BattleHudStyle.GOLD,"winter":Color("#83deec")}
const MENU_MECHANICS := {
    "tutorial":"APRENDA NOTAS,\nSUSTENTAÇÕES E\nAS ESTAÇÕES.",
    "spring":"FLORES ESCONDEM\nAS NOTAS.\nMEMORIZE O ECO.",
    "summer":"EVITE O FOGO.\nELE CONSOME\nSUA ENERGIA.",
    "autumn":"AS FOLHAS VOAM.\nDEIXE PASSAR\nE SIGA O RITMO.",
    "winter":"EVITE O GELO.\nELE CONGELA\nTECLAS VIZINHAS."
}
static var developer_mode: bool = false
var portraits: Array[PaperMusician] = []
var cards: Array[PixelMenuPanel] = []
var actions: Array[Button] = []
var vistas: Array[SeasonCardVista] = []
var seasons: Array[String] = []
var menu_time: float = 0.0
var first_focus: Button
var back_button: Button
var card_w: float = CARD_MAX_W
var backdrop: SeasonCardVista

func _process(delta: float) -> void:
    menu_time+=delta*.45
    for portrait in portraits:
        portrait.rhythm_beat=menu_time

func _ready() -> void:
    Conductor.stop()
    MenuMusic.start()
    texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    backdrop=SeasonCardVista.new()
    backdrop.season="tutorial"
    backdrop.size=Vector2(1280,720)
    add_child(backdrop)
    var dim := ColorRect.new()
    dim.color=Color(.06,.04,.10,.88)
    dim.size=Vector2(1280,720)
    dim.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(dim)
    _build_header()
    _build_total_stars()
    var count: int = LevelDB.LEVELS.size()
    card_w=floor(minf(CARD_MAX_W,(1280.0-2*SIDE_MARGIN-CARD_GAP*float(count-1))/float(count))/2.0)*2.0
    var total_width: float = count*card_w+(count-1)*CARD_GAP
    var start_x: float = round((1280.0-total_width)*.5)
    for i in range(count):
        _build_card(LevelDB.LEVELS[i],start_x+i*(card_w+CARD_GAP),i)
    _build_footer()
    _wire_focus()
    first_focus.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.physical_keycode==KEY_F8 and OS.is_debug_build():
            developer_mode=not developer_mode
            get_viewport().set_input_as_handled()
            get_tree().reload_current_scene()
        elif event.physical_keycode==KEY_ESCAPE:
            get_viewport().set_input_as_handled()
            _go_back()

func _build_header() -> void:
    add_child(_label("ECHO / "+("OFICINA MUSICAL" if developer_mode else "A JORNADA"),Vector2(34,20),Vector2(850,26),20,BattleHudStyle.MUTED,false))
    add_child(_label("EDITOR DE FASES" if developer_mode else "ESCOLHA SUA ESTAÇÃO",Vector2(32,54),Vector2(920,42),40,INK,false))
    add_child(_label("ESCOLHA UMA FASE PARA EDITAR SUAS NOTAS." if developer_mode else "CADA ENCONTRO, UM NOVO RITMO.",Vector2(34,106),Vector2(960,26),20,BattleHudStyle.MUTED,false))

func _build_total_stars() -> void:
    var badge := PixelMenuPanel.new()
    badge.name="TotalStars"
    badge.position=Vector2(1002,44)
    badge.size=Vector2(244,54)
    badge.edge=HIGHLIGHT
    badge.highlighted=true
    badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
    badge.add_child(_label("ESTRELAS %d/%d" % [Progress.total_stars(),Progress.max_total_stars()],Vector2(8,12),Vector2(228,30),20,INK,true))
    add_child(badge)

func _build_footer() -> void:
    back_button=Button.new()
    back_button.name="Back"
    back_button.text="VOLTAR"
    back_button.position=Vector2(34,674)
    back_button.size=Vector2(148,34)
    _style_button(back_button,HIGHLIGHT)
    back_button.pressed.connect(_go_back)
    add_child(back_button)
    if first_focus==null:
        first_focus=back_button
    var hint := _label("SETAS / MOUSE: ESCOLHER   •   ENTER: CONFIRMAR   •   ESC: VOLTAR",Vector2(240,680),Vector2(1006,24),20,BattleHudStyle.MUTED,false)
    hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
    add_child(hint)

func _build_card(level: Dictionary, x: float, index: int) -> void:
    var season: String = str(level["season"])
    var accent: Color = ACCENTS.get(season,INK)
    var status: Dictionary = _read_status(level)
    var card := PixelMenuPanel.new()
    card.name="Card_"+str(level["id"])
    card.position=Vector2(x,CARD_Y)
    card.size=Vector2(card_w,CARD_H)
    card.edge=accent
    add_child(card)
    cards.append(card)
    seasons.append(season)
    var vista := SeasonCardVista.new()
    vista.season=season
    vista.position=Vector2(6,6)
    vista.size=Vector2(card_w-12,212)
    card.add_child(vista)
    vistas.append(vista)
    var portrait: PaperMusician = BossCatalog.create_lord(season)
    vista.add_child(portrait)
    if portrait is SpritePlayer:
        BattleHudStyle.fit_sprite(portrait as SpritePlayer,162,Vector2(round(vista.size.x*.55),208))
    portraits.append(portrait)
    var index_badge := Panel.new()
    index_badge.position=Vector2(12,14)
    index_badge.size=Vector2(38,26)
    index_badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
    index_badge.add_theme_stylebox_override("panel",BattleHudStyle.box(BattleHudStyle.INK,accent,1))
    index_badge.add_child(_label("%02d" % (index+1),Vector2(0,1),Vector2(38,24),20,accent,true))
    card.add_child(index_badge)
    var star_back := Panel.new()
    star_back.position=Vector2(card_w-118,14)
    star_back.size=Vector2(106,26)
    star_back.mouse_filter=Control.MOUSE_FILTER_IGNORE
    star_back.add_theme_stylebox_override("panel",BattleHudStyle.box(BattleHudStyle.INK,accent.darkened(.35),1))
    card.add_child(star_back)
    var progress: Dictionary = Progress.get_level(str(level["id"]))
    var stars := StarRow.new()
    stars.name="Stars"
    stars.total=Progress.MAX_STARS
    stars.filled=float(int(progress["stars"]))
    stars.pixel_art=true
    stars.outline_color=accent
    stars.position=Vector2(card_w-115,15)
    stars.size=Vector2(100,24)
    stars.mouse_filter=Control.MOUSE_FILTER_IGNORE
    card.add_child(stars)
    var title := _label(str(level["name"]),Vector2(14,226),Vector2(card_w-28,34),30,accent,false)
    title.name="Title"
    card.add_child(title)
    var boss: String = str(level["lorde"]).to_upper()
    if season=="tutorial":
        boss="MENTOR"
    elif season=="winter":
        boss="BÓREAS"
    card.add_child(_label(boss,Vector2(14,264),Vector2(card_w-28,24),20,INK,false))
    var difficulty := _label(str(level["difficulty"]),Vector2(14,296),Vector2(card_w-28,24),20,BattleHudStyle.MUTED,false)
    difficulty.tooltip_text="Dificuldade: "+str(level["difficulty"])
    card.add_child(difficulty)
    var rule := ColorRect.new()
    rule.position=Vector2(14,328)
    rule.size=Vector2(card_w-28,2)
    rule.color=Color(accent,.23)
    rule.mouse_filter=Control.MOUSE_FILTER_IGNORE
    card.add_child(rule)
    var mechanic := _label(str(MENU_MECHANICS.get(season,"")),Vector2(14,338),Vector2(card_w-28,74),20,INK,false)
    mechanic.name="Mechanic"
    card.add_child(mechanic)
    var status_label := _label(_status_copy(status,progress),Vector2(14,422),Vector2(card_w-28,48),20,BattleHudStyle.MUTED,false)
    status_label.name="Status"
    status_label.tooltip_text=str(status["text"])
    card.add_child(status_label)
    var action := Button.new()
    action.name="Action"
    action.text="EDITAR NOTAS" if developer_mode else "JOGAR" if bool(status["can_play"]) else "EM BREVE"
    action.disabled=not bool(status["can_edit"] if developer_mode else status["can_play"])
    action.position=Vector2(14,472)
    action.size=Vector2(card_w-28,34)
    _style_button(action,accent)
    action.pressed.connect((_on_edit if developer_mode else _on_play).bind(str(level["id"])))
    card.add_child(action)
    actions.append(action)
    card.mouse_entered.connect(_activate_card.bind(index))
    card.mouse_exited.connect(_restore_focus)
    action.focus_entered.connect(_activate_card.bind(index))
    action.mouse_entered.connect(_activate_card.bind(index))
    if not action.disabled and (first_focus==null or str(level["id"])==LevelDB.selected_id):
        first_focus=action

func _activate_card(index: int) -> void:
    for i in range(cards.size()):
        cards[i].highlighted=i==index
        vistas[i].animated=i==index
    backdrop.season=seasons[index]
    backdrop.queue_redraw()
    portraits[index].play_pose(0,.35)
    if back_button!=null and not actions[index].disabled:
        back_button.focus_neighbor_top=back_button.get_path_to(actions[index])

func _restore_focus() -> void:
    for i in range(actions.size()):
        if actions[i].has_focus():
            _activate_card(i)
            return
    for card in cards:
        card.highlighted=false

func _wire_focus() -> void:
    var available: Array[Button] = []
    for action in actions:
        if not action.disabled:
            available.append(action)
    for i in range(available.size()):
        var button: Button = available[i]
        button.focus_neighbor_left=button.get_path_to(available[(i-1+available.size())%available.size()])
        button.focus_neighbor_right=button.get_path_to(available[(i+1)%available.size()])
        button.focus_neighbor_top=button.get_path_to(back_button)
        button.focus_neighbor_bottom=button.get_path_to(back_button)
    if not available.is_empty():
        back_button.focus_neighbor_top=back_button.get_path_to(first_focus)
        back_button.focus_neighbor_left=back_button.get_path_to(available.back())
        back_button.focus_neighbor_right=back_button.get_path_to(available.front())

func _status_copy(status: Dictionary, progress: Dictionary) -> String:
    if developer_mode:
        var text: String = str(status["text"])
        if text.begins_with("SEM MÚSICA"):
            return "ÁUDIO PENDENTE\nPODE EDITAR"
        if not bool(status["can_play"]):
            return "CHART SEM NOTAS\nPODE EDITAR"
        return text.get_slice("\n",0).replace(" • ","\n").to_upper()
    if not bool(status["can_play"]):
        return "NOVA MELODIA\nEM PRODUÇÃO"
    if int(progress["plays"])>0:
        return "RECORDE %d\nACERTOS %.0f%%" % [int(progress["best_score"]),float(progress["best_ratio"])*100.0]
    return "PRIMEIRO ECO\nA DESCOBRIR"

func _read_status(level: Dictionary) -> Dictionary:
    var audio_path: String = LevelDB.resolve_audio(level)
    if audio_path == "":
        return {
            "text": ("SEM MÚSICA • %s" % LevelDB.suggested_audio_path(level).get_file()) if developer_mode else "Uma nova melodia está a caminho.",
            "color": Color(INK.r, INK.g, INK.b, 0.7),
            "can_play": false,
            "can_edit": true
        }

    var progress: Dictionary = Progress.get_level(str(level["id"]))
    var phrase_count: int = 0
    var note_count: int = 0
    var chart_path: String = str(level["chart"])
    if FileAccess.file_exists(chart_path):
        var chart: Dictionary = ChartIO.load_chart(chart_path)
        var phrases: Array = chart.get("phrases", []) as Array
        phrase_count = phrases.size()
        note_count = ChartData.count_all_notes(phrases)

    if note_count <= 0:
        return {
            "text": "Sem notas — use EDITAR NOTAS." if developer_mode else "Uma nova melodia está a caminho.",
            "color": HIGHLIGHT,
            "can_play": false,
            "can_edit": true
        }

    var ready_text: String = ("%d frases • %d notas" % [phrase_count, note_count]) if developer_mode else "Encontre o seu primeiro eco."
    if int(progress["plays"]) > 0:
        var best_text: String = "RECORDE  %d pts\nMelhor desempenho: %.0f%%" % [int(progress["best_score"]), float(progress["best_ratio"]) * 100.0]
        ready_text = ready_text + "\nRECORDE  %d pts" % int(progress["best_score"]) if developer_mode else best_text
    return {
        "text": ready_text,
        "color": Color(0.10, 0.45, 0.25, 1.0),
        "can_play": true,
        "can_edit": true
    }


func _on_play(level_id: String) -> void:
    LevelDB.selected_id = level_id
    get_tree().change_scene_to_file(BATTLE_SCENE)

func _on_edit(level_id: String) -> void:
    LevelDB.selected_id = level_id
    get_tree().change_scene_to_file(EDITOR_SCENE)

func _go_back() -> void:
    get_tree().change_scene_to_file(MAIN_SCENE)


func _label(text_value: String, pos: Vector2, label_size: Vector2, font_size: int, color: Color, centered: bool) -> Label:
    var label := Label.new()
    label.text=text_value.to_upper()
    label.position=pos.round()
    label.size=label_size
    label.clip_text=true
    label.mouse_filter=Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_override("font",BattleHudStyle.FONT)
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",color)
    if centered:
        label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    return label

func _style_button(button: Button, accent: Color) -> void:
    BattleHudStyle.style_button(button)
    for state in ["normal","hover","pressed"]:
        button.add_theme_stylebox_override(state,BattleHudStyle.box(accent.darkened(.72 if state=="normal" else .55),accent.darkened(.35) if state=="normal" else accent,2))
    button.add_theme_stylebox_override("focus",BattleHudStyle.box(Color(0,0,0,0),HIGHLIGHT,3))
    button.add_theme_stylebox_override("disabled",BattleHudStyle.box(Color("#252535"),Color("#514759"),2))
    button.add_theme_color_override("font_disabled_color",Color("#a69aa9"))

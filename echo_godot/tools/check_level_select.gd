extends SceneTree

var failures: int = 0
var menu: Control
var render: bool = false

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if not condition:
        failures+=1
        push_error("LEVEL SELECT CHECK: "+message)

func _key(key: Key) -> void:
    var event := InputEventKey.new()
    event.keycode=key
    event.physical_keycode=key
    event.pressed=true
    Input.parse_input_event(event)
    await process_frame
    event=event.duplicate()
    event.pressed=false
    Input.parse_input_event(event)
    await process_frame

func _wait_scene(path: String) -> void:
    for i in range(12):
        await process_frame
        if current_scene!=null and current_scene.scene_file_path==path:
            return
    _expect(false,"scene route: "+path)

func _shot(path: String) -> void:
    if not render:
        return
    # Stable portrait frames let screenshots compare composition and text.
    menu.set_process(false)
    for portrait in menu.portraits:
        portrait.set_process(false)
        portrait._show_frame("idle",0)
    await process_frame
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    _expect(root.get_texture().get_image().save_png(path)==OK,"screenshot "+path)

func _check_labels(node: Node) -> void:
    if node is Label:
        var font: Font = node.get_theme_font("font")
        var font_size: int = node.get_theme_font_size("font_size")
        for line in node.text.split("\n"):
            _expect(font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x<=node.size.x,"label width: "+line)
        _expect(node.get_line_count()*font.get_height(font_size)<=node.size.y+2,"label height: "+node.text)
    for child in node.get_children():
        _check_labels(child)

func _run() -> void:
    create_timer(35).timeout.connect(func() -> void: push_error("LEVEL SELECT CHECK timed out"); quit(1))
    render="--render-level-select" in OS.get_cmdline_user_args()
    AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"),true)
    AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),true)
    var menu_player: AudioStreamPlayer = root.get_node("MenuMusic").get("player") as AudioStreamPlayer
    var ui_script = load("res://scripts/ui/LevelSelect.gd")
    ui_script.developer_mode=false
    LevelDB.selected_id="verao"
    menu=load("res://scenes/LevelSelect.tscn").instantiate()
    root.add_child(menu)
    current_scene=menu
    await process_frame
    _expect(menu_player.playing,"menu music starts in stage selection")
    _expect(menu_player.bus==GameSettings.MUSIC_BUS,"menu music follows music volume")
    menu_player.seek(menu_player.stream.get_length()-.12)
    for frame in range(120):
        if menu_player.playing and menu_player.get_playback_position()<1.0:
            break
        await process_frame
    _expect(menu_player.playing and menu_player.get_playback_position()<1.0,"menu track repeats from the beginning")
    if render:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        DisplayServer.window_set_size(Vector2i(1280,720))
    _expect(menu.cards.size()==LevelDB.LEVELS.size(),"all five stages present")
    _expect(menu.portraits[0] is SpriteLord and menu.portraits[0].outfit=="mentor","mentor in tutorial card")
    for i in range(LevelDB.LEVELS.size()):
        var level: Dictionary = LevelDB.LEVELS[i]
        var progress: Dictionary = Progress.get_level(str(level["id"]))
        var card: Control = menu.cards[i]
        var has_notes: bool = ChartData.count_all_notes(ChartIO.load_chart(str(level["chart"])).get("phrases",[]))>0
        var can_play: bool = LevelDB.resolve_audio(level)!="" and has_notes
        _expect(menu.actions[i].disabled==not can_play,"real availability: "+str(level["id"]))
        _expect(card.get_node("Stars").filled==float(progress["stars"]),"saved stars: "+str(level["id"]))
        _expect(card.position.x>=0 and card.position.x+card.size.x<=1280 and card.position.y+card.size.y<=668,"card fits viewport")
        _expect(not card.get_node("Status").text.contains("res://"),"no file paths in player flow")
        _check_labels(card)
    _check_labels(menu.get_node("TotalStars"))
    _expect(root.gui_get_focus_owner()==menu.actions[3],"selected playable stage initially focused")
    await _shot("res://art_preview/selecao_fases_pixel.png")
    await _key(KEY_RIGHT)
    _expect(root.gui_get_focus_owner()==menu.actions[4] and menu.cards[4].highlighted,"Right selects winter")
    await _shot("res://art_preview/selecao_fases_pixel_inverno.png")
    await _key(KEY_DOWN)
    _expect(root.gui_get_focus_owner()==menu.back_button,"Down reaches back button")
    await _key(KEY_UP)
    _expect(root.gui_get_focus_owner()==menu.actions[4],"Up restores latest focused stage")
    menu.cards[1].mouse_entered.emit()
    _expect(menu.cards[1].highlighted and menu.backdrop.season=="spring","mouse previews an upcoming stage")
    menu.cards[1].mouse_exited.emit()
    _expect(menu.cards[4].highlighted,"mouse exit restores keyboard selection")
    # Enter follows the actual JOGAR connection into the selected battle.
    await _key(KEY_ENTER)
    await _wait_scene("res://scenes/Battle.tscn")
    _expect(LevelDB.selected_id=="inverno","Enter launches the chosen level")
    var battle: Node2D = current_scene
    _expect(battle.season_view!=null and battle.counting_in,"battle still opens with count-in and HUD")
    _expect(not menu_player.playing,"menu music stops in battle")
    battle._cancel_count_in()
    await create_timer(root.get_node("Conductor").seconds_per_beat+.05).timeout
    battle._go_to_level_select()
    await _wait_scene("res://scenes/LevelSelect.tscn")
    _expect(menu_player.playing,"menu music restarts after battle")
    # Existing editor entry remains available, including stages without audio.
    ui_script.developer_mode=false
    menu=current_scene
    await _key(KEY_F8)
    await _wait_scene("res://scenes/LevelSelect.tscn")
    menu=current_scene
    _expect(ui_script.developer_mode,"F8 keeps the editor entry")
    for action in menu.actions:
        _expect(not action.disabled and action.text=="EDITAR NOTAS","all editor actions remain enabled")
    for card in menu.cards:
        _check_labels(card)
    await _shot("res://art_preview/selecao_editor_pixel.png")
    menu.actions[2].pressed.emit()
    await _wait_scene("res://scenes/Editor.tscn")
    _expect(LevelDB.selected_id=="outono","editor opens chosen autumn chart")
    _expect(not menu_player.playing,"menu music stays off in editor")
    current_scene.queue_free()
    await process_frame
    ui_script.developer_mode=false
    menu=load("res://scenes/LevelSelect.tscn").instantiate()
    root.add_child(menu)
    current_scene=menu
    await process_frame
    await _key(KEY_ESCAPE)
    await _wait_scene("res://scenes/Main.tscn")
    _expect(current_scene.scene_file_path=="res://scenes/Main.tscn","Escape returns to main menu")
    _expect(menu_player.playing,"menu music resumes on main menu")
    current_scene.queue_free()
    await process_frame
    root.get_node("Conductor").stop()
    print("LEVEL SELECT CHECK: ","PASS" if failures==0 else "FAIL","; ",failures," failures; five cards, saved stars, availability, text fit, keyboard/mouse, Enter, Escape and editor routes")
    quit(0 if failures==0 else 1)

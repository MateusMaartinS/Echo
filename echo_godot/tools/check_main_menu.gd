extends SceneTree

var menu: Control
var failures: int = 0
var render: bool = false

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if not condition:
        failures+=1
        push_error("MAIN MENU CHECK: "+message)

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

func _open_title() -> void:
    if current_scene!=null:
        current_scene.queue_free()
        await process_frame
    menu=load("res://scenes/Main.tscn").instantiate()
    root.add_child(menu)
    current_scene=menu
    await process_frame
    if render:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        DisplayServer.window_set_size(Vector2i(1280,720))

func _shot(path: String) -> void:
    if not render:
        return
    menu.set_process(false)
    for boss in menu.bosses:
        boss.set_process(false)
        boss._show_frame("idle",0)
    await process_frame
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    _expect(root.get_texture().get_image().save_png(path)==OK,"screenshot")

func _run() -> void:
    create_timer(35).timeout.connect(func() -> void: push_error("MAIN MENU CHECK timed out"); quit(1))
    render="--render-main-menu" in OS.get_cmdline_user_args()
    root.get_node("Sfx").ui_sounds_enabled=false
    await _open_title()
    if "--check-main-quit" in OS.get_cmdline_user_args():
        menu.tree_exiting.connect(func() -> void: print("MAIN MENU QUIT CHECK: title closed after Enter on SAIR"))
        menu.entries[4].grab_focus()
        await _key(KEY_ENTER)
        return # Only the real quit action or the failing watchdog can end this run.
    var titles := ["JOGAR","PERSONAGENS","EDITOR","CONFIGURAÇÕES","SAIR"]
    _expect(menu.entries.size()==5,"five text entries")
    _expect(menu.bosses.size()==4,"four bosses frame menu")
    _expect(menu.get_node("Logo") is EchoTitleLogo,"original pixel logo")
    for i in range(5):
        _expect(menu.entries[i].text==titles[i],"menu label "+titles[i])
        _expect(menu.entries[i].get_theme_stylebox("normal") is StyleBoxEmpty,"no button boxes")
        _expect(menu.entries[i].get_theme_stylebox("focus") is StyleBoxEmpty,"no focus boxes")
        _expect(BattleHudStyle.FONT.get_string_size(titles[i],HORIZONTAL_ALIGNMENT_LEFT,-1,30).x+40<=menu.entries[i].size.x,"text fits")
    for boss in menu.bosses:
        _expect(boss.modulate.a<.7,"boss contrast subdued")
        _expect(boss.scale.x==boss.scale.y,"boss aspect ratio preserved")
    var labels: int = 0
    for node in menu.get_children():
        if node is Label or node is Panel:
            labels+=1
    _expect(labels==0,"no subtitle, slogan, season names or boxed menu")
    _expect(menu.selected_index==0 and menu.entries[0].active,"initial selection")
    await _shot("res://art_preview/tela_principal_pixel.png")
    await _key(KEY_UP)
    _expect(menu.selected_index==4 and menu.entries[4].active,"Up wraps to exit")
    await _key(KEY_DOWN)
    _expect(menu.selected_index==0,"Down wraps to play")
    for i in range(3):
        await _key(KEY_DOWN)
    _expect(menu.selected_index==3,"Down navigates to settings")
    var active: int = 0
    for entry in menu.entries:
        active+=int(entry.active)
    _expect(active==1,"one arrow / active entry")
    await _shot("res://art_preview/tela_principal_pixel_configuracoes.png")
    menu.entries[1].mouse_entered.emit()
    _expect(menu.selected_index==1 and menu.entries[1].has_focus(),"mouse selection")
    await _key(KEY_ESCAPE)
    _expect(menu.selected_index==0,"Escape returns to first option")
    await _key(KEY_ENTER)
    await _wait_scene("res://scenes/LevelSelect.tscn")
    _expect(not current_scene.developer_mode,"Play opens player selection")
    await _open_title()
    menu.entries[1].grab_focus()
    await _key(KEY_ENTER)
    await _wait_scene("res://scenes/Wardrobe.tscn")
    _expect(current_scene.preview_id==SkinCatalog.selected_id(),"Characters opens wardrobe without equipping")
    await _open_title()
    menu.entries[2].grab_focus()
    await _key(KEY_ENTER)
    await _wait_scene("res://scenes/LevelSelect.tscn")
    _expect(current_scene.developer_mode,"Editor opens editor selection")
    await _open_title()
    menu.entries[3].grab_focus()
    await _key(KEY_ENTER)
    await _wait_scene("res://scenes/Settings.tscn")
    _expect(current_scene.music_slider!=null and current_scene.sfx_slider!=null,"Settings route")
    # Do not use the settings Back action: it persists settings even unchanged.
    current_scene.queue_free()
    await process_frame
    root.get_node("Conductor").stop()
    print("MAIN MENU CHECK: ","PASS" if failures==0 else "FAIL","; ",failures," failures; logo, panorama, four bosses, flat menu, keyboard/mouse, Escape and four routes")
    quit(0 if failures==0 else 1)

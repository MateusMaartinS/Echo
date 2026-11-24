extends SceneTree

const TEST_SAVE := "res://.godot/hud_reference_frames/wardrobe_test.cfg"
var screen: Control
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error("WARDROBE CHECK: "+message)

func _key(code: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = true
    Input.parse_input_event(event)
    await process_frame
    event.pressed = false
    Input.parse_input_event(event)
    await process_frame

func _shot(path: String) -> void:
    if "--render-wardrobe" not in OS.get_cmdline_user_args():
        return
    await process_frame
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    _expect(root.get_texture().get_image().save_png(path)==OK,"screenshot "+path)

func _run() -> void:
    create_timer(35).timeout.connect(func() -> void: push_error("WARDROBE CHECK timed out"); quit(1))
    root.get_node("Sfx").ui_sounds_enabled = false
    screen = load("res://scenes/Wardrobe.tscn").instantiate()
    root.add_child(screen)
    current_scene = screen
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    DisplayServer.window_set_size(Vector2i(1280,720))
    await process_frame
    _expect(screen.tiles.size()==5,"five visible tiles")
    _expect(screen.tabs.size()==2,"two tabs")
    _expect(screen.preview_id==SkinCatalog.selected_id(),"initial preview matches equipped")
    _expect(screen.preview_title.text==screen.NAMES[screen.selected_index],"preview title matches tile")
    _expect(screen.tiles[screen.selected_index].selected,"one selected tile")
    _expect(screen.tiles[screen.selected_index].has_focus(),"focused tile follows selection")
    var selected_count := 0
    for tile in screen.tiles:
        selected_count += int(tile.selected)
    _expect(selected_count==1,"one highlighted tile")
    await _shot("res://art_preview/tela_visuais_pixel.png")
    screen._select("autumn_female")
    _expect(screen.selected_index==3 and screen.female,"selecting female autumn switches tab")
    _expect(screen.tiles[3].selected and screen.preview_id=="autumn_female","tile and preview synchronized")
    _expect(screen.equip_button.disabled==not SkinCatalog.is_unlocked("autumn_female"),"locked state")
    await _shot("res://art_preview/tela_visuais_bloqueada.png")
    screen._switch_gender(false)
    _expect(screen.preview_id=="autumn" and screen.selected_index==3,"tab preserves season")
    await _key(KEY_TAB)
    _expect(screen.preview_id=="autumn_female" and screen.female,"keyboard can switch character tabs")
    await _key(KEY_TAB)
    await _key(KEY_RIGHT)
    _expect(screen.selected_index==4 and screen.preview_id=="winter","right moves one tile")
    await _key(KEY_LEFT)
    _expect(screen.selected_index==3,"left moves within bottom row")
    await _key(KEY_UP)
    _expect(screen.selected_index==0,"up moves to top row")
    await _key(KEY_LEFT)
    _expect(screen.selected_index==2,"left wraps within top row")
    await _key(KEY_DOWN)
    _expect(screen.selected_index==4,"down chooses nearest bottom tile")
    _expect(screen.tiles[4].has_focus(),"focus matches highlighted tile after keyboard navigation")
    screen.tiles[2].mouse_entered.emit()
    _expect(screen.selected_index==2 and screen.preview_id=="summer","mouse hover updates preview")
    screen.tabs[1].pressed.emit()
    _expect(screen.preview_id=="summer_female" and screen.tiles[2].has_focus(),"mouse tab preserves season and focus")
    screen._select("classic")
    SkinCatalog.storage_path = TEST_SAVE
    screen._refresh()
    _expect(screen.equip_button.disabled and screen.equip_button.text=="EQUIPADA","classic already equipped in isolated save")
    screen._select("classic_female")
    await _key(KEY_ENTER)
    _expect(SkinCatalog.selected_id()=="classic_female","Enter equips selected skin")
    _expect(screen.equip_button.text=="EQUIPADA" and screen.equip_button.disabled,"equipped state independent")
    _expect(screen.tiles[0].selected and screen.tiles[0].equipped,"tile selected and equipped")
    SkinCatalog.storage_path = SkinCatalog.SAVE_PATH
    DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
    screen._select("winter_female")
    await _shot("res://art_preview/tela_visuais_inverno.png")
    print("WARDROBE CHECK: ","PASS" if failures==0 else "FAIL", " (",failures," failures)")
    quit(0 if failures==0 else 1)

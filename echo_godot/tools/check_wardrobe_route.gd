extends SceneTree

var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error("WARDROBE ROUTE: "+message)

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

func _scene(path: String) -> void:
    for i in range(12):
        await process_frame
        if current_scene != null and current_scene.scene_file_path == path:
            return
    _expect(false,"expected "+path)

func _run() -> void:
    create_timer(45).timeout.connect(func() -> void: push_error("WARDROBE ROUTE timed out"); quit(1))
    root.get_node("Sfx").ui_sounds_enabled = false
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    DisplayServer.window_set_size(Vector2i(1280,720))
    Input.warp_mouse(Vector2(510,360)) # Over a title option while it is constructed.
    await process_frame
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    current_scene = main
    await process_frame
    print("ROUTE: main initial")
    main.entries[0].grab_focus()
    await _key(KEY_ENTER)
    await _scene("res://scenes/LevelSelect.tscn")
    print("ROUTE: phases")
    Input.warp_mouse(Vector2(510,360)) # Re-enter title with the cursor on PERSONAGENS.
    await process_frame
    await _key(KEY_ESCAPE)
    await _scene("res://scenes/Main.tscn")
    print("ROUTE: main returned")
    main = current_scene
    _expect(main.entries.size()==5,"title finished construction under cursor")
    Input.warp_mouse(Vector2(510,400)) # Over the fourth wardrobe tile during its construction.
    await process_frame
    main._on_wardrobe_pressed()
    await _scene("res://scenes/Wardrobe.tscn")
    print("ROUTE: wardrobe opened")
    var wardrobe: Control = current_scene
    _expect(wardrobe.tiles.size()==5,"wardrobe finished construction under cursor")
    _expect(wardrobe.preview_id == SkinCatalog.selected_id(),"correct preview")
    await _key(KEY_RIGHT)
    _expect(wardrobe.selected_index >= 0,"navigation responds")
    await _key(KEY_ESCAPE)
    await _scene("res://scenes/Main.tscn")
    _expect(current_scene.entries.size()==5,"Escape returns to complete main menu")
    print("ROUTE: wardrobe returned to main")
    print("WARDROBE ROUTE: ","PASS" if failures == 0 else "FAIL"," (",failures," failures)")
    quit(0 if failures == 0 else 1)

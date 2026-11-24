extends SceneTree

# Integration check: real Battle, chart, input, Judge and ScoreManager.
# Hold fixtures are in memory only. Never calls Progress.submit or equips a skin.
var battle: Node2D
var failures: int = 0
var render: bool = false
var conductor: Node

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if not condition:
        failures+=1
        push_error("SUMMER HUD CHECK: "+message)

func _disable_processes(node: Node) -> void:
    node.set_process(false)
    for child in node.get_children():
        _disable_processes(child)

func _step(seconds: float) -> void:
    conductor.song_position=seconds
    battle._process(0.0)
    battle.opponent_spawner._process(0.0)
    battle.player_spawner._process(0.0)
    for spawner in [battle.player_spawner,battle.opponent_spawner]:
        for note in spawner.active_notes:
            if is_instance_valid(note):
                note.set_process(false)
                note._process(0.0)
    battle.judge._process(0.0)
    battle.characters._process(.016)
    for actor in [battle.characters.musician,battle.characters.lord]:
        actor._process(.016)
    battle.season_view._process(0.0)

func _key(lane: int, pressed: bool = true) -> void:
    var keys := [KEY_D,KEY_F,KEY_J,KEY_K]
    var event := InputEventKey.new()
    event.physical_keycode=keys[lane]
    event.pressed=pressed
    battle.player_input._input(event)

func _shot(suffix: String) -> void:
    if not render:
        return
    battle.season_view.queue_redraw()
    await process_frame
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    var error: Error = root.get_texture().get_image().save_png("res://art_preview/hud_solana_aplicada_%s.png" % suffix)
    _expect(error==OK,"capture "+suffix)

func _run() -> void:
    create_timer(45).timeout.connect(func() -> void: push_error("SUMMER HUD CHECK timed out"); quit(1))
    render="--render-summer-hud" in OS.get_cmdline_user_args()
    conductor=root.get_node("Conductor")
    AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),true)
    AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"),true)
    LevelDB.selected_id="verao"
    battle=load("res://scenes/Battle.tscn").instantiate()
    root.add_child(battle)
    current_scene=battle
    await process_frame
    if render:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        DisplayServer.window_set_size(Vector2i(1280,720))
    _expect(battle.season_view!=null,"live summer view exists")
    _expect(battle.pause_menu is BattlePauseMenu,"pixel pause menu")
    _expect(battle.counting_in and battle.paused,"initial count-in blocks gameplay")
    battle._cancel_count_in()
    await create_timer(conductor.seconds_per_beat+.05).timeout
    _expect(battle.player_spawner.target_x==BattleHudStyle.HIT_X,"player receptor aligned")
    _expect(battle.opponent_spawner.target_x==BattleHudStyle.HIT_X,"opponent receptor aligned")
    _expect(battle.player_spawner.lane_y==BattleHudStyle.PLAYER_LANES,"player lane geometry")
    _expect(battle.opponent_spawner.lane_y==BattleHudStyle.OPPONENT_LANES,"opponent lane geometry")
    _expect(is_equal_approx(battle.player_spawner.travel_time,1.5),"original approach time")
    _expect(battle.characters.musician.outfit==SkinCatalog.selected_id(),"equipped skin respected")
    _expect(not battle.hud.get_node("Help").visible and not battle.hud.get_node("TopBar").visible,"old HUD hidden")
    _expect(is_equal_approx(battle.characters.normalization["boss"]["height"]/battle.characters.normalization["player"]["height"],1.3),"visible height ratio")
    battle.pause_menu._toggle_controls()
    _expect(battle.pause_menu.controls_open,"controls reachable")
    await _shot("controles")
    battle._on_escape()
    _expect(not battle.pause_menu.controls_open and battle.paused and not battle.counting_in,"Escape returns from controls to pause")
    battle._on_escape()
    _expect(battle.counting_in and battle.player_input.blocked,"resume count-in")
    await create_timer(conductor.seconds_per_beat*3+.06).timeout
    _expect(not battle.paused and not battle.counting_in and conductor.is_playing(),"music resumes on fourth beat")
    _expect(battle.pause_menu.count_label.text=="VAI!","fourth beat says VAI")
    await create_timer(conductor.seconds_per_beat+.05).timeout
    _expect(not battle.pause_menu.count_label.visible,"count overlay closes")
    conductor.set_process(false)
    _disable_processes(battle)
    _step(conductor.beat_to_seconds(32.5))
    _expect(battle.phase=="OPPONENT" and not battle.season_view.player_turn,"real observe turn")
    _expect(battle.characters.next_lord_note>0 and battle.season_view.hit_times[1]>0,"boss animation pulses receptor")
    for note in battle.opponent_spawner.active_notes:
        if is_instance_valid(note) and not note.judged:
            _expect(note.pixel_style,"opponent notes use shared pixel style")
    await _shot("observe")
    _step(conductor.beat_to_seconds(36.0))
    _key(0)
    _key(0,false)
    _expect(battle.score.energy==90 and battle.season_view.feedback=="FOGO!","real fire penalty and feedback")
    _step(conductor.beat_to_seconds(36.5))
    _key(1)
    _key(1,false)
    _expect(battle.score.score==100 and battle.score.combo==1,"real Perfect score and combo")
    _expect(battle.season_view.feedback=="PERFEITO" and battle.season_view.player_turn,"real player feedback")
    await _shot("sua_vez")
    _step(conductor.beat_to_seconds(37.0)+.075)
    _key(3)
    _key(3,false)
    _expect(battle.season_view.feedback=="BOM" and battle.score.combo==2,"real Good feedback")
    _step(conductor.beat_to_seconds(38.0)+.20)
    _expect(battle.season_view.feedback=="ERRO" and battle.score.combo==0,"real missed note feedback")
    await _shot("erro")
    # Exercise holds without changing the user's chart (it currently has none).
    battle.player_spawner.clear_all()
    battle.opponent_spawner.clear_all()
    var now: float = conductor.get_song_position()+.5
    battle.player_spawner.spawn_note(0,now,"normal",.75)
    _step(now)
    _key(0)
    _expect(battle.judge.holding.has(0),"hold begins through original PlayerInput")
    var held: Node2D = battle.judge.holding[0]
    _step(now+.35)
    _expect(is_equal_approx(held.position.x,BattleHudStyle.HIT_X) and held.tail_len>0,"hold head anchored, tail shrinks")
    await _shot("sustentacao")
    _step(now+.76)
    _key(0,false)
    _expect(battle.judge.holding.is_empty() and battle.season_view.feedback=="SEGUROU","hold completion feedback")
    now=conductor.get_song_position()+.5
    battle.player_spawner.spawn_note(1,now,"normal",.75)
    _step(now)
    _key(1)
    _key(1,false)
    _expect(battle.season_view.feedback=="SOLTOU" and battle.judge.holding.is_empty(),"early hold release feedback")
    now=conductor.get_song_position()+.5
    battle.player_spawner.spawn_note(2,now,"normal",.75)
    _step(now)
    _key(2)
    var energy_before: float = battle.score.energy
    battle._pause_game()
    _expect(battle.paused and battle.player_input.blocked and not battle.judge.enabled,"pause blocks judgment")
    _expect(battle.judge.holding.is_empty() and battle.score.energy==energy_before,"pause forgives active hold")
    var frozen_time: float = conductor.get_song_position()
    var frozen_pose: float = battle.characters.musician.action_elapsed
    conductor._process(.5)
    battle.characters._process(.5)
    battle.characters.musician._process(.5)
    _expect(conductor.get_song_position()==frozen_time and battle.characters.musician.action_elapsed==frozen_pose,"clock and pose stay frozen")
    await _shot("pausa")
    # Verify result styling without submitting a result to real progress.
    battle.pause_menu.hide_pause()
    var result: Panel = battle.hud.get_node("ResultPanel")
    var stars := StarRow.new()
    stars.total=4
    stars.filled=3
    stars.size=Vector2(200,36)
    result.add_child(stars)
    result.get_node("Hint").text="NOVO RECORDE!\nR = REINICIAR  •  ESC = FASES"
    battle.season_view.style_result(true)
    result.show()
    await _shot("resultado")
    battle.season_view.style_result(false)
    await _shot("derrota")
    result.hide()
    # Every cosmetic keeps its own aspect ratio and a stable scale across poses.
    for skin in SkinCatalog.SKINS:
        var actor: SpritePlayer = SkinCatalog.create_player(str(skin["id"])) as SpritePlayer
        root.add_child(actor)
        actor.set_process(false)
        var fit: Dictionary = BattleHudStyle.fit_sprite(actor,196,Vector2(162,346))
        _expect(not fit.is_empty(),"visible bounds: "+str(skin["id"]))
        var original_scale: Vector2 = actor.scale
        for lane in range(4):
            actor.play_pose(lane)
            actor._process(.07)
            _expect(actor.scale==original_scale and is_equal_approx(actor.scale.x,actor.scale.y),"stable aspect ratio: "+str(skin["id"]))
        actor.queue_free()
    # Restart the real scene, including the original rewind/count-in path.
    await battle._on_restart_pressed()
    for frame in range(8):
        await process_frame
        if current_scene!=null:
            break
    battle=current_scene
    _expect(battle.season_view!=null and battle.counting_in,"restart rebuilds live HUD and count-in")
    battle._cancel_count_in()
    await create_timer(conductor.seconds_per_beat+.05).timeout
    battle.queue_free()
    await process_frame
    # The tutorial keeps its original layout; seasonal bosses share the new HUD.
    LevelDB.selected_id="tutorial"
    battle=load("res://scenes/Battle.tscn").instantiate()
    root.add_child(battle)
    current_scene=battle
    await process_frame
    _expect(battle.season_view==null and not battle.player_spawner.pixel_style,"tutorial keeps its layout")
    _expect(battle.get_node("Background").visible and battle.hud.get_node("TopBar").visible,"tutorial keeps its HUD")
    if battle.counting_in:
        battle._cancel_count_in()
    await create_timer(conductor.seconds_per_beat+.05).timeout
    battle.queue_free()
    await process_frame
    conductor.stop()
    print("SUMMER HUD CHECK: ","PASS" if failures==0 else "FAIL", "; ",failures," failures; chart input, judgments, holds, pause, count-in, restart, 10 skins, tutorial regression")
    quit(0 if failures==0 else 1)

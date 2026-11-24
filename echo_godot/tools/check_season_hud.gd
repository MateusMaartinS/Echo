extends SceneTree

# Seasonal integration/visual regression. Fixtures and missing audio exist only
# in memory; this check never writes charts, progression, equipment or settings.
var battle: Node2D
var conductor: Node
var failures: int = 0
var render: bool = false
var hud_regions: Array[PackedByteArray] = []
var fixture_audio: AudioStreamWAV

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if not condition:
        failures+=1
        push_error("SEASON HUD CHECK: "+message)

func _disable(node: Node) -> void:
    node.set_process(false)
    for child in node.get_children():
        _disable(child)

func _step(beat: float) -> void:
    conductor.song_position=conductor.beat_to_seconds(beat)
    battle._process(0)
    battle.opponent_spawner._process(0)
    battle.player_spawner._process(0)
    for spawner in [battle.player_spawner,battle.opponent_spawner]:
        for note in spawner.active_notes:
            if is_instance_valid(note):
                note.set_process(false)
                note._process(0)
    battle.judge._process(0)
    battle.characters._process(.016)
    battle.characters.musician._process(.016)
    battle.characters.lord._process(.016)
    if battle.season_view.scenery!=null:
        battle.season_view.scenery._process(.016)

func _key(lane: int, down: bool = true) -> void:
    var keys := [KEY_D,KEY_F,KEY_J,KEY_K]
    var event := InputEventKey.new()
    event.physical_keycode=keys[lane]
    event.pressed=down
    battle.player_input._input(event)

func _image() -> Image:
    battle.season_view.queue_redraw()
    if battle.season_view.scenery!=null:
        battle.season_view.scenery.queue_redraw()
    battle.season_fx.queue_redraw()
    await process_frame
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func _shot(level_id: String, suffix: String) -> void:
    if render:
        var screenshot: Image = await _image()
        _expect(screenshot.save_png("res://art_preview/hud_%s_estacao_%s.png" % [level_id,suffix])==OK,"screenshot "+level_id)

func _prime() -> void:
    _disable(battle)
    conductor.set_bpm(144)
    var notes: Array = [
        {"beat":8.0,"lane":0},{"beat":8.5,"lane":1},{"beat":9.0,"lane":2,"duration":1.0},
        {"beat":9.5,"lane":3},{"beat":10.0,"lane":0},{"beat":10.5,"lane":2},
        {"beat":11.0,"lane":1},{"beat":11.5,"lane":3},{"beat":12.0,"lane":0}
    ]
    battle.phrases=[{"start_beat":8.0,"end_beat":13.0,"notes":notes}]
    battle.first_response_beat=12.0
    battle.last_player_beat=17.0
    battle.opponent_last_beat=13.0
    battle.score.reset()
    battle.score.total_notes=9
    battle.phase="OPPONENT"
    battle.paused=false
    battle.counting_in=false
    battle.starting_song=null
    battle.pause_menu.hide_pause()
    battle.pause_menu.hide_count()
    battle.player_input.set_blocked(false)
    battle.judge.forgive_active_holds()
    battle.opponent_spawner.clear_all()
    battle.player_spawner.clear_all()
    battle.opponent_spawner.spawn_chart_notes(notes,0,0)
    var responses: Array = notes.duplicate(true)
    for note in responses:
        note["beat"]=float(note["beat"])+4.0
    battle.player_spawner.spawn_chart_notes(responses,0,0)
    battle.characters.setup_lord_notes(notes)
    battle.arena.set_active_field("OPPONENT")
    conductor.play_stream(fixture_audio)
    conductor.set_process(false)

func _run() -> void:
    create_timer(45).timeout.connect(func() -> void: push_error("SEASON HUD CHECK timed out"); quit(1))
    render="--render-season-hud" in OS.get_cmdline_user_args()
    conductor=root.get_node("Conductor")
    AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"),true)
    AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"),true)
    fixture_audio=AudioStreamWAV.new()
    fixture_audio.mix_rate=8000
    fixture_audio.format=AudioStreamWAV.FORMAT_8_BITS
    var samples := PackedByteArray()
    samples.resize(8000*20)
    samples.fill(128)
    fixture_audio.data=samples
    fixture_audio.take_over_path("res://audio/music/outono.wav")
    for level_id in ["verao","inverno","outono","primavera","tutorial"]:
        LevelDB.selected_id=level_id
        battle=load("res://scenes/Battle.tscn").instantiate()
        root.add_child(battle)
        current_scene=battle
        await process_frame
        if render:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
            DisplayServer.window_set_size(Vector2i(1280,720))
        _expect(battle.season_view!=null,"shared HUD: "+level_id)
        _expect(battle.pause_menu is BattlePauseMenu,"shared pause: "+level_id)
        _expect(battle.player_spawner.target_x==478.0 and battle.player_spawner.lane_y==BattleHudStyle.PLAYER_LANES,"same receptor geometry: "+level_id)
        _expect(battle.characters.musician.outfit==SkinCatalog.selected_id(),"equipped skin: "+level_id)
        _expect(is_equal_approx(battle.characters.normalization["boss"]["height"],254.8),"same visible boss height: "+level_id)
        if level_id=="tutorial":
            _expect(battle.characters.lord is SpriteLord and battle.characters.lord.outfit=="mentor","mentor sprite: tutorial")
            _expect(battle.season_view.scenery!=null and battle.season_view.scenery.season=="tutorial","tutorial rehearsal scenery")
        if battle.counting_in:
            battle._cancel_count_in()
            await create_timer(conductor.seconds_per_beat+.05).timeout
        _prime()
        _step(8.5)
        await _shot(level_id,"observe")
        _step(12.0)
        _key(0)
        _key(0,false)
        _expect(battle.score.score==100 and battle.season_view.feedback=="PERFEITO","real input/scoring: "+level_id)
        await _shot(level_id,"sua_vez")
        if battle.season_view.scenery!=null:
            var stage: Node2D = battle.season_view.scenery
            var previous_time: float = stage.motion_time
            stage._process(.25)
            _expect(stage.motion_time>previous_time,"decoration animates: "+level_id)
            conductor.pause()
            previous_time=stage.motion_time
            var previous_beat: float = stage.music_beat
            stage._process(.5)
            _expect(stage.motion_time==previous_time and stage.music_beat==previous_beat,"decoration freezes on pause: "+level_id)
            conductor.resume()
            if level_id=="inverno":
                stage.music_beat=4
                _expect(stage._strong_beat()==1,"strong beat crystal pulse")
                stage.music_beat=5
                _expect(stage._strong_beat()==0,"crystal pulse decays")
        # Opaque HUD interiors stay identical while the exposed landscape changes.
        battle.player_spawner.clear_all()
        battle.opponent_spawner.clear_all()
        battle.season_view.feedback=""
        battle.season_view.hit_times=[-10.0,-10.0]
        if render:
            var frame: Image = await _image()
            var regions: Array[Rect2i] = [Rect2i(342,138,904,228),Rect2i(342,440,904,228),Rect2i(342,20,904,52)]
            for i in range(regions.size()):
                var pixels: PackedByteArray = frame.get_region(regions[i]).get_data()
                if level_id=="verao":
                    hud_regions.append(pixels)
                else:
                    _expect(pixels==hud_regions[i],"HUD stays above background, region %d: %s" % [i,level_id])
            var ground: Dictionary = {"inverno":Color("#7597a4"),"outono":Color("#b18b69"),"primavera":Color("#8da78b")}
            if ground.has(level_id):
                _expect(frame.get_pixel(1278,718).is_equal_approx(ground[level_id]),"landscape reaches far right: "+level_id)
        # Original seasonal mechanics still run through PlayerInput and Judge.
        var now: float = conductor.get_song_position()
        var season: String = str(battle.level["season"])
        if season=="winter":
            battle.player_spawner.spawn_note(1,now,"ice")
            _key(1)
            _key(1,false)
            _expect(battle.judge.is_lane_frozen(0) and battle.judge.is_lane_frozen(2),"ice freezes neighboring lanes")
            await _shot(level_id,"gelo")
        elif season=="autumn":
            battle.player_spawner.spawn_note(1,now+.1,"leaf")
            var leaf: Node2D = battle.player_spawner.active_notes.back()
            leaf._process(0)
            _expect(leaf.fleeing,"leaf escapes before receiver")
            var energy: float = battle.score.energy
            _key(1)
            _key(1,false)
            _expect(battle.score.energy==energy,"leaf has no penalty")
        elif season=="spring":
            battle.season_fx.events=[{"type":"flower","start_beat":11.0,"end_beat":14.0,"field":"player","half":"top"}]
            await _shot(level_id,"flores")
            _expect(battle.season_fx.player_spawner==battle.player_spawner,"flower mechanic follows updated lanes")
        battle._pause_game()
        _expect(battle.paused and battle.player_input.blocked and battle.pause_menu.is_open(),"pause still works: "+level_id)
        battle.queue_free()
        await process_frame
        conductor.stop()
    print("SEASON HUD CHECK: ","PASS" if failures==0 else "FAIL","; ",failures," failures; four bosses and mentor, preserved HUD, full-width landscapes, original hazards and paused animation")
    quit(0 if failures==0 else 1)

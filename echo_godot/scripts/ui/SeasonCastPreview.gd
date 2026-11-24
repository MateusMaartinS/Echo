extends Node2D

# Inspect the cast without depending on finished charts/music for each season.
const SEASONS := ["spring", "summer", "autumn", "winter"]
const NAMES := ["PRIMAVERA", "VERÃO", "OUTONO", "INVERNO"]
const DETAILS := ["Flora • pétalas e flores", "Solana • cabelo solar e fogo", "Silas • sobretudo e folhas", "Boreas • capa e cristais de gelo"]
var puppets: Array[PaperMusician] = []
var sheet_season: int = -1
var pose_names := ["REPOUSO", "CIMA", "DIREITA", "ESQUERDA", "BAIXO"]

func _ready() -> void:
    _build_cast()
    if "--export-season-preview" in OS.get_cmdline_user_args():
        await _save_preview("res://art_preview/lordes.png")
        for season_index in range(4):
            for puppet in puppets:
                remove_child(puppet)
                puppet.queue_free()
            puppets.clear()
            sheet_season = season_index
            for i in range(5):
                var puppet := BossCatalog.create_lord(SEASONS[season_index])
                puppet.position = Vector2(140 + i * 250, 395)
                puppet.scale = Vector2(1.24, 1.24)
                puppet.preview_pose = i - 1
                add_child(puppet)
                puppets.append(puppet)
            queue_redraw()
            await _save_preview("res://art_preview/lorde_%s.png" % SEASONS[season_index])
        get_tree().quit()

func _build_cast() -> void:
    for i in range(4):
        var puppet := BossCatalog.create_lord(SEASONS[i])
        puppet.position = Vector2(180 + i * 310, 387)
        puppet.scale = Vector2(1.40, 1.40)
        puppet.preview_pose = -1
        add_child(puppet)
        puppets.append(puppet)

func _save_preview(path: String) -> void:
    await get_tree().process_frame
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    var error: Error = get_viewport().get_texture().get_image().save_png(path)
    assert(error == OK)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        var lane: int = Lanes.lane_for_key(event.physical_keycode)
        for puppet in puppets:
            puppet.preview_pose = -2
            if lane >= 0:
                puppet.play_pose(lane, 0.5)

func _draw() -> void:
    draw_rect(Rect2(0,0,1280,720), Color("#f7f3e9"))
    var graphite := Color("#393b35")
    var title: String = "ECHO  /  LORDES DAS ESTAÇÕES" if sheet_season == -1 else "ECHO  /  %s — POSES" % NAMES[sheet_season]
    draw_string(ThemeDB.fallback_font, Vector2(62,87), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, graphite)
    draw_string(ThemeDB.fallback_font, Vector2(62,125), "Bonecos de papel • traços de lápis • quatro identidades", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, graphite)
    for i in range(4 if sheet_season == -1 else 5):
        var x: float = 180 + i * 310 if sheet_season == -1 else 140 + i * 250
        draw_line(Vector2(x - 100,534), Vector2(x + 100,534), Color(0.23,0.24,0.21,0.16), 1.0)
        draw_string(ThemeDB.fallback_font, Vector2(x - 125,580), NAMES[i] if sheet_season == -1 else pose_names[i], HORIZONTAL_ALIGNMENT_CENTER, 250, 21, graphite)
        if sheet_season == -1:
            draw_string(ThemeDB.fallback_font, Vector2(x - 150,610), DETAILS[i], HORIZONTAL_ALIGNMENT_CENTER, 300, 16, graphite)
    draw_string(ThemeDB.fallback_font, Vector2(62,677), "Setas / D F J K: experimentar movimentos • roupas acompanham as poses", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, graphite)

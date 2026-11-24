extends Node2D

@export_enum("classic", "winter", "summer", "autumn", "spring") var collection: String = "classic"
var actors: Array[PaperMusician] = []
const TITLES := ["REPOUSO","CIMA","DIREITA","ESQUERDA","BAIXO"]
const LANES := [-1,0,1,2,3]

func _ready() -> void:
    var skins: Array = [collection,collection+"_female"]
    for row in range(2):
        for column in range(5):
            var actor := SkinCatalog.create_player(str(skins[row]))
            actor.position = Vector2(140+column*250,242+row*270)
            actor.scale = Vector2(.9,.9)
            actor.preview_pose = LANES[column]
            add_child(actor)
            actors.append(actor)
    if "--export-player-preview" in OS.get_cmdline_user_args():
        await get_tree().process_frame
        await RenderingServer.frame_post_draw
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png("res://art_preview/protagonistas_%s.png" % {"classic":"animacoes","winter":"inverno","summer":"verao","autumn":"outono","spring":"primavera"}[collection])
        get_tree().quit()

func _draw() -> void:
    draw_rect(Rect2(0,0,1280,720),Color("#f7f3e9"))
    draw_string(ThemeDB.fallback_font,Vector2(34,62),"ECHO  /  PROTAGONISTAS — %s" % {"classic":"ANIMAÇÕES","winter":"INVERNO","summer":"VERÃO","autumn":"OUTONO","spring":"PRIMAVERA"}[collection],HORIZONTAL_ALIGNMENT_LEFT,-1,29,SeasonMenuStyle.INK)
    draw_string(ThemeDB.fallback_font,Vector2(34,96),"Duas versões • cinco ações • três quadros por sequência",HORIZONTAL_ALIGNMENT_LEFT,-1,18,SeasonMenuStyle.MUTED)
    for column in range(5):
        var x: float = 140+column*250
        draw_string(ThemeDB.fallback_font,Vector2(x-110,135),TITLES[column],HORIZONTAL_ALIGNMENT_CENTER,220,17,SeasonMenuStyle.INK)
        for y in [333.0,603.0]:
            draw_line(Vector2(x-90,y),Vector2(x+90,y),Color(.23,.24,.21,.15),1.0)
    draw_string(ThemeDB.fallback_font,Vector2(34,361),"MASCULINO",HORIZONTAL_ALIGNMENT_LEFT,-1,14,SeasonMenuStyle.MUTED)
    draw_string(ThemeDB.fallback_font,Vector2(34,631),"FEMININO",HORIZONTAL_ALIGNMENT_LEFT,-1,14,SeasonMenuStyle.MUTED)
    draw_string(ThemeDB.fallback_font,Vector2(34,684),"Arte original preservada • alinhamento pelo chão • animações nas notas e no guarda-roupa",HORIZONTAL_ALIGNMENT_LEFT,-1,17,SeasonMenuStyle.MUTED)

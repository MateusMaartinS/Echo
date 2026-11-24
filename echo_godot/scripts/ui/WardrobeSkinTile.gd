extends Button
class_name WardrobeSkinTile

var skin_id := ""
var caption := ""
var accent: Color = BattleHudStyle.GOLD
var unlocked := true
var equipped := false
var selected := false
var vista: SeasonCardVista
var portrait: SpritePlayer
var stars: StarRow
var overlay: WardrobeTileOverlay

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    for state in ["normal","hover","pressed","focus","disabled"]:
        add_theme_stylebox_override(state,StyleBoxEmpty.new())
    vista = SeasonCardVista.new()
    vista.position = Vector2(6,6)
    vista.size = Vector2(size.x-16,145)
    add_child(vista)
    stars = StarRow.new()
    stars.total = 4
    stars.pixel_art = true
    stars.position = Vector2(63,176)
    stars.size = Vector2(108,22)
    stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(stars)
    overlay = WardrobeTileOverlay.new()
    overlay.tile = self
    overlay.size = size
    add_child(overlay)

func configure(id: String, title: String, season: String, color: Color, available: bool, in_use: bool, active: bool, earned: int) -> void:
    var changed: bool = skin_id != id
    skin_id = id
    caption = title
    accent = color
    unlocked = available
    equipped = in_use
    selected = active
    vista.season = season
    vista.queue_redraw()
    if changed:
        if portrait:
            vista.remove_child(portrait)
            portrait.queue_free()
        portrait = SkinCatalog.create_player(id) as SpritePlayer
        vista.add_child(portrait)
        BattleHudStyle.fit_sprite(portrait,112,Vector2(vista.size.x*.5,137))
    portrait.modulate = Color(1,1,1,.38) if not available else Color.WHITE
    stars.filled = float(4 if season == "tutorial" else earned)
    stars.outline_color = accent
    stars.queue_redraw()
    queue_redraw()
    overlay.queue_redraw()

func _draw() -> void:
    BattleHudStyle.draw_panel(self,Rect2(Vector2.ZERO,size-Vector2(4,4)),Color("#211a31"),BattleHudStyle.GOLD if selected else Color(accent,.72),3 if selected else 2)
    draw_rect(Rect2(6,150,size.x-16,2),Color(accent,.48))
    draw_string(BattleHudStyle.FONT,Vector2(16,171),caption,HORIZONTAL_ALIGNMENT_LEFT,size.x-45,20,BattleHudStyle.GOLD if selected else BattleHudStyle.CREAM)
    if selected:
        BattleHudStyle.draw_arrow(self,Vector2(size.x-24,164),1,9,BattleHudStyle.GOLD)

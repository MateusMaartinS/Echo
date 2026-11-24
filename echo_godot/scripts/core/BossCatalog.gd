extends RefCounted
class_name BossCatalog

const SPRITE_BOSSES: Dictionary = {
    "tutorial": {"id":"mentor","name":"MENTOR"},
    "summer": {"id":"solana","name":"SOLANA"},
    "winter": {"id":"boreas","name":"BOREAS"},
    "autumn": {"id":"silas","name":"SILAS"},
    "spring": {"id":"flora","name":"FLORA"},
}

static func create_lord(season: String) -> PaperMusician:
    if SPRITE_BOSSES.has(season):
        var singer := SpriteLord.new()
        singer.outfit = str(SPRITE_BOSSES[season]["id"])
        return singer
    var lord := PaperLord.new()
    lord.season = season
    return lord

static func display_name(season: String) -> String:
    return str(SPRITE_BOSSES[season]["name"]) if SPRITE_BOSSES.has(season) else "LORDE"

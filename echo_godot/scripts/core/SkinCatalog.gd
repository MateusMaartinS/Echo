extends RefCounted
class_name SkinCatalog

# Cosmetics are derived from saved best stars, so existing records count too.
const REQUIRED_STARS: int = 4
const DEFAULT_ID: String = "classic"
const SAVE_PATH: String = "user://wardrobe.cfg"
static var storage_path: String = SAVE_PATH

const SKINS: Array = [
    {"id": "classic", "name": "CLÁSSICA • MASCULINA", "season": "tutorial", "level": "", "description": "Camiseta branca, cargo verde e tênis. Seu primeiro som."},
    {"id": "classic_female", "name": "CLÁSSICA • FEMININA", "season": "tutorial", "level": "", "description": "Cabelo com mechas, fones, camiseta branca, cargo verde e microfone."},
    {"id": "spring", "name": "PRIMAVERA • MASCULINA", "season": "spring", "level": "primavera", "description": "Boina bege, camisa com flores, calça verde-clara e tênis brancos."},
    {"id": "spring_female", "name": "PRIMAVERA • FEMININA", "season": "spring", "level": "primavera", "description": "Vestido longo florido, coroa de flores nos fones e sandálias claras."},
    {"id": "summer", "name": "VERÃO • MASCULINA", "season": "summer", "level": "verao", "description": "Regata branca, bermuda cargo verde e chinelos para tocar no calor."},
    {"id": "summer_female", "name": "VERÃO • FEMININA", "season": "summer", "level": "verao", "description": "Top branco, canga florida, sandálias e fones com mechas rosas."},
    {"id": "autumn", "name": "OUTONO • MASCULINA", "season": "autumn", "level": "outono", "description": "Camisa xadrez verde, calça cargo e tênis para acompanhar as folhas."},
    {"id": "autumn_female", "name": "OUTONO • FEMININA", "season": "autumn", "level": "outono", "description": "Casaco vinho, saia xadrez, meia-calça escura e botas de outono."},
    {"id": "winter", "name": "INVERNO • MASCULINA", "season": "winter", "level": "inverno", "description": "Jaqueta acolchoada, cachecol verde e botas para responder ao frio."},
    {"id": "winter_female", "name": "INVERNO • FEMININA", "season": "winter", "level": "inverno", "description": "Casaco com gola de pelo, cachecol e fones com mechas rosas."},
]

static func get_skin(skin_id: String) -> Dictionary:
    for skin in SKINS:
        if str(skin["id"]) == skin_id:
            return skin
    return SKINS[0]

static func is_known(skin_id: String) -> bool:
    return str(get_skin(skin_id)["id"]) == skin_id

static func earned(skin_id: String, stars: int) -> bool:
    return is_known(skin_id) and (str(get_skin(skin_id)["level"]) == "" or stars >= REQUIRED_STARS)

static func stars_for(skin_id: String) -> int:
    var level_id: String = str(get_skin(skin_id)["level"])
    return int(Progress.get_level(level_id)["stars"]) if level_id != "" else 0

static func is_unlocked(skin_id: String) -> bool:
    return earned(skin_id, stars_for(skin_id))

static func selected_id(path: String = "") -> String:
    var config := ConfigFile.new()
    if config.load(storage_path if path == "" else path) != OK:
        return DEFAULT_ID
    var skin_id: String = str(config.get_value("wardrobe", "selected", DEFAULT_ID))
    return skin_id if is_unlocked(skin_id) else DEFAULT_ID

static func equip(skin_id: String, path: String = "") -> Error:
    if not is_unlocked(skin_id):
        return ERR_UNAUTHORIZED
    var config := ConfigFile.new()
    config.load(storage_path if path == "" else path)
    config.set_value("wardrobe", "selected", skin_id)
    return config.save(storage_path if path == "" else path)

static func create_player(skin_id: String = "") -> PaperMusician:
    # Explicit IDs are for wardrobe previews, including locked outfits.
    var resolved_id: String = skin_id if is_known(skin_id) else selected_id()
    var player: PaperMusician = SpritePlayer.new() if resolved_id in ["classic","classic_female","spring","spring_female","winter","winter_female","summer","summer_female","autumn","autumn_female"] else PaperMusician.new()
    player.outfit = resolved_id
    return player

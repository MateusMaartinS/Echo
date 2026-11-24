extends RefCounted
class_name Progress

# Progresso do jogador por fase (estrelas e recordes), salvo em
# user://progress.cfg. Tudo estático: não precisa de autoload.
#
# ESTRELAS = fração das notas que o jogador ACERTOU (Perfect/Good/Bad) ao
# terminar a fase. Zerar a energia (derrota) não dá estrelas.
# Ajuste os limiares aqui:
const MAX_STARS: int = 4
const STAR_THRESHOLDS: Array = [0.50, 0.70, 0.85, 0.95]   # 1★, 2★, 3★, 4★
const SAVE_PATH: String = "user://progress.cfg"

static func stars_for_ratio(ratio: float) -> int:
    var stars: int = 0
    for i in range(STAR_THRESHOLDS.size()):
        if ratio >= float(STAR_THRESHOLDS[i]) - 0.0001:
            stars = i + 1
    return stars

# Limiar (0..1) da PRÓXIMA estrela, ou -1 se já tem todas.
static func next_threshold(stars: int) -> float:
    if stars >= STAR_THRESHOLDS.size():
        return -1.0
    return float(STAR_THRESHOLDS[stars])

static func get_level(level_id: String) -> Dictionary:
    var data: Dictionary = {"stars": 0, "best_score": 0, "best_ratio": 0.0, "best_combo": 0, "plays": 0}
    var config: ConfigFile = ConfigFile.new()
    if config.load(SAVE_PATH) != OK:
        return data
    for key in data.keys():
        data[key] = config.get_value(level_id, str(key), data[key])
    return data

# Registra o resultado de uma partida. Devolve:
#   stars     = estrelas ganhas NESTA partida
#   best      = estrelas do recorde (já considerando esta partida)
#   new_best  = bateu o recorde de pontos/estrelas
static func submit(level_id: String, victory: bool, hit_ratio: float, score: int, max_combo: int) -> Dictionary:
    var previous: Dictionary = get_level(level_id)
    var earned: int = stars_for_ratio(hit_ratio) if victory else 0
    var best_stars: int = maxi(int(previous["stars"]), earned)
    var improved: bool = victory and (earned > int(previous["stars"]) or score > int(previous["best_score"]))

    var config: ConfigFile = ConfigFile.new()
    config.load(SAVE_PATH)
    config.set_value(level_id, "plays", int(previous["plays"]) + 1)
    config.set_value(level_id, "stars", best_stars)
    if victory:
        config.set_value(level_id, "best_score", maxi(int(previous["best_score"]), score))
        config.set_value(level_id, "best_ratio", maxf(float(previous["best_ratio"]), hit_ratio))
        config.set_value(level_id, "best_combo", maxi(int(previous["best_combo"]), max_combo))
    else:
        config.set_value(level_id, "best_score", int(previous["best_score"]))
        config.set_value(level_id, "best_ratio", float(previous["best_ratio"]))
        config.set_value(level_id, "best_combo", int(previous["best_combo"]))
    if config.save(SAVE_PATH) != OK:
        push_warning("Não foi possível salvar o progresso em " + SAVE_PATH)

    return {"stars": earned, "best": best_stars, "new_best": improved}

static func total_stars() -> int:
    var total: int = 0
    for level in LevelDB.LEVELS:
        total += int(get_level(str((level as Dictionary)["id"]))["stars"])
    return total

static func max_total_stars() -> int:
    return LevelDB.LEVELS.size() * MAX_STARS

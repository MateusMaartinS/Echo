extends Node
class_name ScoreManager

signal score_changed(score: int)
signal combo_changed(combo: int)
signal energy_changed(energy: float)

var score: int = 0
var combo: int = 0
var max_combo: int = 0
var energy: float = 100.0
var total_notes: int = 0
var judged_notes: int = 0
var hit_notes: int = 0   # Perfect + Good + Bad (base das estrelas)
var weighted_points: float = 0.0

# --- Balanceamento da energia (mexa só aqui) -------------------------------
# Valores positivos recuperam, negativos tiram. A energia vai de 0 a 100.
const ENERGY_PERFECT: float = 1.5
const ENERGY_GOOD: float = 1.0
const ENERGY_BAD: float = 0.0
const ENERGY_MISS: float = -6.0
const ENERGY_ERROR: float = -3.0
const ENERGY_FIRE: float = -10.0
const ENERGY_HOLD_OK: float = 3.0
const ENERGY_HOLD_BREAK: float = -3.0
# A cada N acertos seguidos (combo múltiplo de N) recupera um bônus extra.
const COMBO_MILESTONE: int = 10
const ENERGY_COMBO_BONUS: float = 3.0

func reset() -> void:
    score = 0
    combo = 0
    max_combo = 0
    energy = 100.0
    total_notes = 0
    judged_notes = 0
    hit_notes = 0
    weighted_points = 0.0

func register_judgment(result: String) -> void:
    if result in ["Perfect", "Good", "Bad", "Miss", "Error"]:
        judged_notes += 1
    if result in ["Perfect", "Good", "Bad"]:
        hit_notes += 1
    match result:
        "Perfect":
            score += 100 + combo * 5
            combo += 1
            weighted_points += 1.0
            energy += ENERGY_PERFECT
            _check_combo_milestone()
        "Good":
            score += 70 + combo * 3
            combo += 1
            weighted_points += 0.8
            energy += ENERGY_GOOD
            _check_combo_milestone()
        "Bad":
            score += 30
            combo += 1
            weighted_points += 0.5
            energy += ENERGY_BAD
            _check_combo_milestone()
        "Miss":
            combo = 0
            energy += ENERGY_MISS
        "Error":
            combo = 0
            energy += ENERGY_ERROR
        "Fire":
            # Apertou uma nota de fogo.
            combo = 0
            energy += ENERGY_FIRE
        "Ice":
            # Gelo não tira energia: o castigo é as teclas congelarem.
            pass
        "HoldOK":
            # Segurou a nota longa até o fim: bônus (a cabeça já pontuou).
            score += 50 + combo * 2
            energy += ENERGY_HOLD_OK
        "HoldBreak":
            # Soltou a nota longa cedo.
            combo = 0
            energy += ENERGY_HOLD_BREAK
            weighted_points = maxf(weighted_points - 0.4, 0.0)
    energy = clamp(energy, 0.0, 100.0)
    max_combo = max(max_combo, combo)
    score_changed.emit(score)
    combo_changed.emit(combo)
    energy_changed.emit(energy)

func _check_combo_milestone() -> void:
    if COMBO_MILESTONE > 0 and combo > 0 and combo % COMBO_MILESTONE == 0:
        energy += ENERGY_COMBO_BONUS

# Fração de notas acertadas (0 a 1). É isso que define as estrelas.
func get_hit_ratio() -> float:
    if total_notes <= 0:
        return 1.0
    return clampf(float(hit_notes) / float(total_notes), 0.0, 1.0)

func get_accuracy() -> float:
    if total_notes <= 0:
        return 100.0
    return clamp((weighted_points / float(total_notes)) * 100.0, 0.0, 100.0)

func get_grade() -> String:
    var acc := get_accuracy()
    if acc >= 95.0:
        return "*****"
    if acc >= 85.0:
        return "****"
    if acc >= 70.0:
        return "***"
    if acc >= 55.0:
        return "**"
    if acc > 0.0:
        return "*"
    return "F"

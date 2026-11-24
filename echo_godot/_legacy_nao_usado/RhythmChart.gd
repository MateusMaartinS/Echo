extends Resource
class_name RhythmChart

@export var song_name: String = ""
@export var artist: String = ""
@export var bpm: float = 100.0
@export var difficulty: String = "Normal"
@export var song: AudioStream
@export var rounds: Array[RoundData] = []

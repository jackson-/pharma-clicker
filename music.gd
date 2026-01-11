extends AudioStreamPlayer

const MUSIC_START: AudioStream = preload("res://audio/start.mp3")
const MUSIC_LOOP: AudioStream = preload("res://audio/loop1.mp3")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.finished.connect(_on_finished)
	self.play_music(MUSIC_START)


func play_music(music_file: AudioStream) -> void:
	# Check if the requested music is already playing to prevent restarting it
	if self.stream == music_file and self.is_playing():
		return

	# Assign the new audio file to the stream property
	self.stream = music_file
	
	# Start playback
	self.play()
	
func _on_finished() -> void:
	play_music(MUSIC_LOOP)

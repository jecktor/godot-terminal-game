extends Node


enum AudioBuses { MASTER, SFX, BGM }

const DATA_PATH := "res://src/data/"

var sfx := AudioStreamPlayer.new()
var bgm := AudioStreamPlayer.new()
var sfx_volume := 0
var bgm_volume := 0


func _ready() -> void:
	add_child(sfx)
	add_child(bgm)
	
	sfx.set_bus("sfx")
	bgm.set_bus("bgm")


func load_file(folder: String, file_path: String,  local := true) -> String:
	var file := File.new()
	var error := ""
	var data := ""
	
	if local:
		file_path = DATA_PATH + folder + "/" + file_path
		
	if !file.file_exists(file_path):
		error = "File: " + file_path + " not found!"
		
	elif file.open(file_path, File.READ) != 0:
		error = "Error opening: " + file_path
		
	if !error:
		data = file.get_as_text()
		
	file.close()
	
	if !data:
		return error
		
	return data


func load_json(file_path: String, local := true) -> Dictionary:
	var file := File.new()
	var error := ""
	var res := {}
	
	if local:
		file_path = DATA_PATH + "json/" + file_path
		
	if !file.file_exists(file_path):
		error = "File: " + file_path + " not found!"
		
	elif file.open(file_path, File.READ) != 0:
		error = "Error opening: " + file_path
		
	if !error:
		var parsed := JSON.parse(file.get_as_text())
		
		if parsed.error != 0:
			error = parsed.error_string
			
		else:
			res = parsed.result
			
	file.close()
	
	if !res:
		res = { "error": error }
		
	return res


func write_json(file_path: String, data: Dictionary, local := true) -> void:
	var file := File.new()
	var error := ""
	
	if local:
		file_path = DATA_PATH + "json/" + file_path
		
	if !file.file_exists(file_path):
		error = "File: " + file_path + " not found!"
		
	elif file.open(file_path, File.WRITE) != 0:
		error = "Error opening: " + file_path
		
	if error:
		print(error)
		
		file.close()
		return
		
	file.store_line(to_json(data))
	file.close()


func play_sound(stream: AudioStream, player: AudioStreamPlayer) -> void:
	if player.playing:
		player.stop()
		
	player.set_stream(stream)
	player.play()


func change_volume(bus: int, db: float) -> void:
	AudioServer.set_bus_volume_db(bus, lerp(AudioServer.get_bus_volume_db(bus), db, 0.5))
	AudioServer.set_bus_mute(bus, db == -24 if true else false)


func change_scene(path: String) -> void:
	assert(get_tree().change_scene(path) == OK)

extends Node


enum ScreenMode { FULLSCREEN, WINDOWED }

var current_mode: int

onready var vp := get_tree().get_root()
onready var base_size := Vector2(1920, 1080)


func _ready() -> void:
	set_windowed()


func set_fullscreen() -> void:
	var window_size := OS.get_screen_size()
	
	current_mode = ScreenMode.FULLSCREEN
	
	if OS.get_name() == "Windows" && window_size == base_size:
				## Not sure if this works outside of Windows / native resolution.
				## MacOS didn't like it, nor smaller resolutions.
		OS.set_window_fullscreen(true)
		
	else:
		var scale := min(window_size.x / base_size.x, window_size.y / base_size.y)
		var scaled_size := (base_size * scale).round()
		
		var margins := Vector2(window_size.x - scaled_size.x, window_size.y - scaled_size.y)
		var screen_rect := Rect2((margins / 2).round(), scaled_size)
		
		OS.set_borderless_window(true)
		OS.set_window_position(OS.get_screen_position())
		OS.set_window_size(Vector2(window_size.x, window_size.y + 1)) ## Black magic?
		vp.set_size(scaled_size) ## Not sure this is strictly necessary.
		vp.set_attach_to_screen_rect(screen_rect)


func set_windowed() -> void:
	var window_size := OS.get_screen_size()
	
	current_mode = ScreenMode.WINDOWED
	
	## Sets the windowed version to an arbitrary 80% of screen size here.
	var scale := min(window_size.x / base_size.x, window_size.y / base_size.y) * 0.8
	var scaled_size := (base_size * scale).round()
	
	var window_x := (window_size.x / 2) - (scaled_size.x / 2)
	var window_y := (window_size.y / 2) - (scaled_size.y / 2)
	OS.set_borderless_window(false)
	OS.set_window_fullscreen(false)
	OS.set_window_position(Vector2(window_x, window_y))
	OS.set_window_size(scaled_size)
	vp.set_size(scaled_size)

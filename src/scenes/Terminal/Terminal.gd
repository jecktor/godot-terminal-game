## Unix-like terminal clone.
##
## Imitates the behavior of a unix command line interface.
## Can perform actions over DirectoryObject and FileObject instances
## contained in a DirectoryObjectTree instance.
class_name Terminal
extends Control


export var font_size := 21
export var max_history_size := 100

var dir_tree := DirectoryObjectTree.new("dir_tree.json")

var opened_file : FileObject

var is_process_running := false

var input_history := []
var _current_history_item := 0

var _cached_input := ""

onready var display := $Display
onready var input := $Wrapper/Input
onready var prompt := $Wrapper/Prompt
onready var terminal_commands := $TerminalCommands


func _ready() -> void:
	if dir_tree.parse_error:
		add_to_display("FATAL: Error parsing directory tree: " + dir_tree.parse_error + "\n")
		
	display.get_font("font").set("size", font_size)
	update_prompt(dir_tree.current_dir.path)
	
	terminal_commands.date([], [])
	add_to_display(Global.load_file("txt", "greet.txt"))
	
	input.grab_focus()


func _input(event: InputEvent):
	if event is InputEventKey && event.pressed:
		
		## Handle change font size.
		if event.control && event.scancode in [KEY_EQUAL, KEY_MINUS]:
			
			if event.scancode == KEY_EQUAL && font_size <= 30:
				font_size += 2
				
			if event.scancode == KEY_MINUS && font_size >= 10:
				font_size -= 2
				
			display.get_font("font").set("size", font_size)


func add_to_history(item: String) -> void:
	if input_history.size() >= max_history_size:
		input_history.pop_front()
		
	input_history.append(item)
	_current_history_item = input_history.size() - 1


func add_to_display(content: String) -> void:
	var new_line := "\n" + content
	
	display.text += new_line
	display.cursor_set_line(display.get_line_count() - 1)
	display.clear_undo_history()


func update_prompt(dir_name: String) -> void:
	if dir_tree.current_dir.path == dir_tree.home_path:
		dir_name = "~"
		
	prompt.text = "[root@localhost " + dir_name + "]$ "


func open_file(file: FileObject, prompt_text := "") -> void:
	# warning-ignore:return_value_discarded
	opened_file = file
	_cached_input = display.text
	
	display.disconnect("gui_input", self, "_on_Display_gui_input")
	display.text = opened_file.content
	display.show_line_numbers = true
	display.clear_undo_history()
	display.grab_focus()
	
	input.editable = false
	
	if "\n" in prompt_text:
		$Wrapper.set_global_position(Vector2($Wrapper.rect_position.x, $Wrapper.rect_position.y - 20))
		
	prompt.text = prompt_text
	display.connect("gui_input", self, "_on_Display_edit_gui_input")
	
	display.readonly = false


func close_file() -> void:
	# warning-ignore:return_value_discarded
	display.disconnect("gui_input", self, "_on_Display_edit_gui_input")
	display.connect("gui_input", self, "_on_Display_gui_input")
	display.show_line_numbers = false
	display.text = _cached_input
	
	if "\n" in prompt.text:
		$Wrapper.set_global_position(Vector2($Wrapper.rect_position.x, $Wrapper.rect_position.y + 20))
		
	update_prompt(dir_tree.current_dir.path)
	
	input.editable = true
	input.grab_focus()
	
	display.readonly = true
	
	opened_file = null
	_cached_input = ""


func save_file() -> void:
	if is_process_running || !opened_file: return
	
	is_process_running = true
	opened_file.content = display.text
	
	var save_info := " " + str(display.get_line_count()) + "L " + str(display.text.length()) + "C Written"
	
	if "\n" in prompt.text:
		prompt.text = prompt.text.insert(prompt.text.find("\n"), save_info)
		
	else:
		prompt.text = prompt.text.insert(prompt.text.size(), save_info)
		
	yield(get_tree().create_timer(1.0), "timeout")
	prompt.text = prompt.text.replace(save_info, "")
	
	is_process_running = false

## Private methods

func _format_input(user_input: String) -> Dictionary:
	var raw_instruction := user_input.split(" ")
	var command : String = raw_instruction[0]
	var params := []
	var flags := []
	
	raw_instruction.remove(0)
	
	if raw_instruction.size() > 0:
		for param in raw_instruction:
			
			if param.length() > 1 && param[0] == "-":
				flags.append(param)
				
			elif param:
				params.append(param)
				
	return { "command": command, "params": params, "flags": flags }

## Signals

## Input signals
func _on_Display_gui_input(_event: InputEvent):
	input.grab_focus()


func _on_Display_edit_gui_input(event: InputEvent):
	if event is InputEventKey && event.pressed && !is_process_running:
		if event.control:
			
			## Handle exit.
			if event.shift && event.scancode == KEY_X:
				close_file()
				
			## Handle Save.
			if event.scancode == KEY_S:
				save_file()


func _on_Input_gui_input(event: InputEvent):
	if event is InputEventKey && event.pressed && !is_process_running:
		
		## Handle clear shortcut.
		if event.control && event.scancode == KEY_L:
			terminal_commands.clear([], [])
			
		## Handle history.
		if event.scancode in [KEY_UP, KEY_DOWN] && input_history.size() > 0:
			
			if event.scancode == KEY_UP && _current_history_item > 0:
				_current_history_item -= 1
				
			if event.scancode == KEY_DOWN && _current_history_item < input_history.size() - 1:
				_current_history_item += 1
				
			input.set_text(input_history[_current_history_item])
			input.grab_focus()
			
		## Handle Autocompletion.
		if event.scancode == KEY_TAB && input.get_text():
			var autocomplete : String = input.get_text()
			var args := autocomplete.split(" ")
			
			if args.size() > 1:
				autocomplete = args[args.size() - 1]
				
			for child in dir_tree.current_dir.children:
				
				if autocomplete in child.name.substr(0, autocomplete.length()):
					
					if child is DirectoryObject:
						args[args.size() - 1] = child.name + "/"
						
					else:
						if child.extension:
							args[args.size() - 1] = child.name + "." + child.extension
							
						else:
							args[args.size() - 1] = child.name
							
					input.set_text(args.join(" "))
					
		input.caret_position = input.get_text().length()


func _on_Input_text_entered(user_input: String) -> void:
	if user_input && !is_process_running:
		input.clear()
		
		user_input = user_input.dedent()
		
		add_to_history(user_input)
		add_to_display("\n" + prompt.text + " " + user_input)
		
		terminal_commands.validate_input(_format_input(user_input))

# Custom signals

func _on_exception_occurred(where: String, message: String) -> void:
	var err := ""
	
	if where == "shell":
		err = where + ": " + message + "\nType 'help' for a list of commands."
		
	else:
		err = where + ": " + message + "\nTry 'man " + where + "' for more information."
		
	add_to_display(err)

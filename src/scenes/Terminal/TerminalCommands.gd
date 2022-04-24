extends Node


signal exception_occurred(where, message)

var commands_refs := [
	funcref(self, "cat"),
	funcref(self, "cd"),
	funcref(self, "clear"),
	funcref(self, "date"),
	funcref(self, "edit"),
	funcref(self, "exit"),
	funcref(self, "help"),
	funcref(self, "history"),
	funcref(self, "ls"),
	funcref(self, "man"),
	funcref(self, "mkdir"),
	funcref(self, "mv"),
	funcref(self, "pwd"),
	funcref(self, "rm"),
	funcref(self, "rmdir"),
	funcref(self, "touch")
]

onready var terminal := get_parent()


func validate_input(instruction: Dictionary) -> void:
	for command in commands_refs:
		
		if instruction.command == command.function:
			command.call_func(instruction.params, instruction.flags)
			
			return
			
	emit_signal("exception_occurred", "shell", instruction.command + ": Command not found")


func validate_flags(flags: Array, valid_flags: Array) -> Dictionary:
	var options := { "valid": [], "invalid": [] }
	
	if flags.size() > 0:
		for flag in flags:
			
			if flag in valid_flags:
				options.valid.append(flag)
				
			else:
				options.invalid.append(flag)
				
	return options

## Commands

func cat(params: Array, flags: Array) -> void:
	var options := validate_flags(flags, ["-n", "--number"])
	
	if options.invalid.size() > 0:
		emit_signal("exception_occurred", "cat", "Unknown option: " + options.invalid[0])
		return
		
	if params.empty():
		emit_signal("exception_occurred", "cat", "Missing operand")
		return
		
	if params.size() > 1:
		emit_signal("exception_occurred", "cat", "Unknown operand: " + params[1])
		return
		
	var file : TerminalObject = terminal.dir_tree.search(params[0])
	
	if !file:
		emit_signal("exception_occurred", "cat", params[0] + ": No such file or directory")
		return
		
	if file is DirectoryObject:
		emit_signal("exception_occurred", "cat", params[0] + ": Is a directory")
		return
		
	if !file.content:
		return
		
	if !options.valid:
		terminal.add_to_display(file.content)
		
	else:
		var file_lines : PoolStringArray = file.content.split("\n")
		
		for i in range(file_lines.size()):
			terminal.add_to_display("\t" + str(i + 1) + "  " + file_lines[i])


func cd(params: Array, flags: Array) -> void:
	if flags.size() > 0:
		emit_signal("exception_occurred", "cd", "Unknown option: " + flags[0])
		return
		
	if params.empty():
		params.append(terminal.dir_tree.home_path)
		
	if params.size() > 1:
		emit_signal("exception_occurred", "cd", "Unknown operand: " + params[1])
		return
		
	var dir : TerminalObject = terminal.dir_tree.search(params[0])
	
	if !dir:
		emit_signal("exception_occurred", "cd", params[0] + ": No such file or directory")
		return
		
	if dir is FileObject:
		emit_signal("exception_occurred", "cd", params[0] + ": Not a directory")
		return
		
	terminal.dir_tree.current_dir = dir
	terminal.update_prompt(dir.name)


func clear(params: Array, flags: Array) -> void:
	if params.size() > 0:
		emit_signal("exception_occurred", "clear", "Unknown operand: " + params[0])
		return
		
	if flags.size() > 0:
		emit_signal("exception_occurred", "clear", "Unknown option: " + flags[0])
		return
		
	terminal.display.text = ""


func date(params: Array, flags: Array) -> void:
	if params.size() > 0:
		emit_signal("exception_occurred", "date", "Unknown operand: " + params[0])
		return
		
	if flags.size() > 0:
		emit_signal("exception_occurred", "date", "Unknown option: " + flags[0])
		return
		
	var date := OS.get_datetime()
	
	var WEEKDAYS := ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
	var MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	
	var weekday : String = WEEKDAYS[date.weekday]
	var month : String = MONTHS[date.month - 1]
	
	var time := { "day": str(date.day), "hour": str(date.hour), "minute": str(date.minute), "second": str(date.second) }
	
	for k in time.keys():
		if time[k].length() == 1:
			time[k] = time[k].insert(0, "0")
			
	terminal.add_to_display(weekday + " " + month + " " + time.day + " " + time.hour + ":" + time.minute + ":" + time.second + " " + str(date.year))


func edit(params: Array, flags: Array) -> void:
	if flags.size() > 0:
		emit_signal("exception_occurred", "edit", "Unknown option: " + flags[0])
		return
		
	if params.empty():
		emit_signal("exception_occurred", "edit", "Missing operand")
		return
		
	if params.size() > 1:
		emit_signal("exception_occurred", "edit", "Unknown operand: " + params[1])
		return
		
	var file : TerminalObject = terminal.dir_tree.search(params[0])
	
	if !file:
		emit_signal("exception_occurred", "edit", params[0] + ": No such file or directory")
		return
		
	if file is DirectoryObject:
		emit_signal("exception_occurred", "edit", params[0] + ": Is a directory")
		return
		
	var prompt_text := ""
	
	if file.extension:
		prompt_text = "\"" + file.name + "." + file.extension + "\""
		
	else:
		prompt_text = "\"" + file.name + "\""
		
	prompt_text += "\n^ + Shift X: Exit     ^S: Save     ^Z: Undo     ^ + Shift Z: Redo"
	
	terminal.open_file(file, prompt_text)


func exit(_params: Array, _flags: Array) -> void:
	var dict_tree : Dictionary = terminal.dir_tree.to_dictionary()
	Global.write_json("dir_tree.json", dict_tree)
	
	get_tree().quit()


func help(params: Array, flags: Array) -> void:
	if params.size() > 0:
		emit_signal("exception_occurred", "help", "Unknown operand: " + params[0])
		return
		
	if flags.size() > 0:
		emit_signal("exception_occurred", "help", "Unknown option: " + flags[0])
		return
		
	var content := """	COMMAND			DESCRIPTION					ARGUMENT(S)

	cat			print file content				[FILE]
	cd			change directory				[DIRECTORY]
	clear		clear the terminal screen
	date		print current datetime
	edit		open file in editor				[FILE]
	exit		exit the terminal
	help		print this help
	history		print previous commands
	ls			list directory contents			[DIRECTORY]
	man			print manual entry				[ENTRY]
	mkdir		create directory				[DIRECTORY]
	mv			move (rename) files				[SOURCE] [DEST]
	pwd			print working directory
	rm			remove files or directories		[FILE]
	rmdir		remove empty directories		[DIRECTORY]
	touch		create file						[FILE]

For more information on a specific command, check its respective manual entry.
For example, try 'man man'."""
	
	terminal.add_to_display(content)


func history(params: Array, flags: Array) -> void:
	if params.size() > 0:
		emit_signal("exception_occurred", "history", "Unknown operand: " + params[0])
		return
		
	if flags.size() > 0:
		emit_signal("exception_occurred", "history", "Unknown option: " + flags[0])
		return
		
	for i in range(terminal.input_history.size()):
		terminal.add_to_display(str(i) + ": " + terminal.input_history[i])


func ls(params: Array, flags: Array) -> void:
	var options := validate_flags(flags, ["-a", "--all"])
	
	if options.invalid.size() > 0:
		emit_signal("exception_occurred", "ls", "Unknown option: " + options.invalid[0])
		return
		
	var dir : DirectoryObject = terminal.dir_tree.current_dir
	
	if params.size() > 0:
		if params.size() > 1:
			emit_signal("exception_occurred", "ls", "Unknown operand: " + params[1])
			return
			
		dir = terminal.dir_tree.search(params[0], true)
		
	if !dir:
		emit_signal("exception_occurred", "ls", params[0] + ": No such file or directory")
		return
		
	if options.valid:
		terminal.add_to_display(".\n..")
		
	if dir.children.size() > 0:
		dir.children.sort_custom(terminal.dir_tree, "sort_dir_children")
		
		for child in dir.children:
			
			if !options.valid && child.name[0] == ".":
				continue
				
			var new_line := ""
			
			if child is DirectoryObject:
				new_line = new_line.insert(0, child.name + "/")
				
			else:
				if child.extension:
					new_line = new_line.insert(0, child.name + "." + child.extension)
					
				else:
					new_line = new_line.insert(0, child.name)
					
			terminal.add_to_display(new_line)


func man(params: Array, flags: Array) -> void:
	if flags.size() > 0:
		emit_signal("exception_occurred", "man", "Unknown option: " + flags[0])
		return
		
	if params.empty():
		emit_signal("exception_occurred", "man", "What manual entry do you want?\nFor example, try 'man man'.")
		return
		
	if params.size() > 1:
		emit_signal("exception_occurred", "man", "Unknown operand: " + params[1])
		return
		
	var man_pages := Global.load_json("man_pages.json")
	
	if !man_pages.has(params[0]):
		emit_signal("exception_occurred", "man", "No manual entry for " + params[0])
		return
		
	var entry : String = man_pages[params[0]]
	terminal.add_to_display(entry)


func mkdir(params: Array, flags: Array) -> void:
	if flags.size() > 0:
		emit_signal("exception_occurred", "mkdir", "Unknown option: " + flags[0])
		return
		
	if params.empty():
		emit_signal("exception_occurred", "mkdir", "Missing operand")
		return
		
	if params.size() > 1:
		emit_signal("exception_occurred", "mkdir", "Unknown operand: " + params[1])
		return
		
	var dir_path : String = params[0]
	
	if dir_path.ends_with("/") && dir_path != terminal.dir_tree.root_path:
		dir_path.erase(dir_path.length() - 1, 1)
		
	var parent : DirectoryObject = terminal.dir_tree.search(dir_path + "/..", true)
	
	if !parent:
		emit_signal("exception_occurred", "mkdir", "Cannot create directory: '" + dir_path + "': No such file or directory")
		return
		
	var dir_name := dir_path.substr(dir_path.find_last("/") + 1)
	
	if !dir_name.is_valid_filename():
		emit_signal("exception_occurred", "mkdir", "Cannot create directory: '" + dir_path + "': Invalid file name")
		return
		
	var dir_exists := false
	
	if dir_name == "." || dir_name == "..":
		dir_exists = true
		
	if !dir_exists:
		var new_dir_path := parent.path
		
		if new_dir_path == terminal.dir_tree.root_path:
			new_dir_path += dir_name
			
		else:
			new_dir_path += "/" + dir_name
			
		for child in parent.children:
			
			if child.path == new_dir_path:
				dir_exists = true
				break
				
	if dir_exists:
		emit_signal("exception_occurred", "mkdir", "Cannot create directory: '" + dir_path + "': File exists")
		return
		
	var new_dir : DirectoryObject = terminal.dir_tree.create_directory(dir_name, [], parent)
	parent.add_child(new_dir)


func mv(params: Array, flags: Array) -> void:
	if flags.size() > 0:
		emit_signal("exception_occurred", "mv", "Unknown option: " + flags[0])
		return
		
	if params.size() < 2:
		emit_signal("exception_occurred", "mv", "Missing operand")
		return
		
	if params.size() > 2:
		emit_signal("exception_occurred", "mv", "Unknown operand: " + params[2])
		return
		
	var source : TerminalObject = terminal.dir_tree.search(params[0])
	
	if !source:
		emit_signal("exception_occurred", "mv", params[0] + ": No such file or directory")
		return
		
	if source.path == terminal.dir_tree.root_path:
		emit_signal("exception_occurred", "mv", "Cannot move or rename root directory")
		return
		
	if source.path == terminal.dir_tree.home_path:
		emit_signal("exception_occurred", "mv", "Cannot move or rename home directory")
		return
		
	var dest : TerminalObject = terminal.dir_tree.search(params[1])
	
	if !dest:
		var new_name : String = params[1]
		
		if new_name.ends_with("/"):
			new_name.erase(new_name.length() - 1, 1)
			
		var d_parent : DirectoryObject = terminal.dir_tree.search(new_name + "/..", true)
		
		if !d_parent || d_parent.path != source.parent.path:
			emit_signal("exception_occurred", "mv", "Cannot move file to: '" + params[1] + "': No such file or directory")
			return
			
		new_name = new_name.substr(new_name.find_last("/") + 1)
		
		if !new_name.is_valid_filename():
			emit_signal("exception_occurred", "mv", "Cannot rename file: '" + params[1] + "': Invalid file name")
			return
			
		if source is FileObject:
			var name_ext := Array(new_name.split("."))
			
			if name_ext.size() > 1:
				if !source.extension:
					 source.path += "." + name_ext.back()
					
				source.extension = name_ext.pop_back()
				
				if name_ext.size() > 1:
					new_name = PoolStringArray(name_ext).join(".")
					
				else:
					new_name = name_ext[0]
					
			else:
				source.extension = ""
				
			source.name = new_name
			
		else:
			source.name = new_name
			
			if source.children.size() > 0:
				terminal.dir_tree.update_dir_children_path(source)
				
	else:
		if dest is FileObject:
			emit_signal("exception_occurred", "mv", params[1] + ": Not a directory")
			return
			
		if source.path == dest.path:
			emit_signal("exception_occurred", "mv", "Cannot move: '" + params[0] + "' inside itself")
			return
			
		if source.parent.path == dest.path:
			return
			
		if source is DirectoryObject && source.path in dest.path:
			emit_signal("exception_occurred", "mv", "Cannot move: '" + params[0] + "' to a subdirectory of itself: '" + params[1] + "'")
			return
			
		var new_path := ""
		
		if source is FileObject:
			new_path = terminal.dir_tree.create_object_path(dest.path, source.name, source.extension)
			
		else:
			new_path = terminal.dir_tree.create_object_path(dest.path, source.name)
			
		if dest.children.size() > 0:
			for child in dest.children:
				
				if child.path == new_path:
					emit_signal("exception_occurred", "mv", "File '" + params[0] + "' exists in directory: '" + params[1] + "'")
					return
					
		source.path = new_path
		
		if source is DirectoryObject && source.children.size() > 0:
			terminal.dir_tree.update_dir_children_path(source)
			
		source.parent.children.erase(source)
		source.parent = dest
		dest.add_child(source)


func pwd(params: Array, flags: Array) -> void:
	if params.size() > 0:
		emit_signal("exception_occurred", "pwd", "Unknown operand: " + params[0])
		return
		
	if flags.size() > 0:
		emit_signal("exception_occurred", "pwd", "Unknown option: " + flags[0])
		return
		
	terminal.add_to_display(terminal.dir_tree.current_dir.path)


func rm(params: Array, flags: Array) -> void:
	var options := validate_flags(flags, ["-r", "-R", "--recursive"])
	
	if options.invalid.size() > 0:
		emit_signal("exception_occurred", "rm", "Unknown option: " + options.invalid[0])
		return
		
	if params.empty():
		emit_signal("exception_occurred", "rm", "Missing operand")
		return
		
	if params.size() > 1:
		emit_signal("exception_occurred", "rm", "Unknown operand: " + params[1])
		return
		
	var obj : TerminalObject = terminal.dir_tree.search(params[0])
	
	if !obj:
		emit_signal("exception_occurred", "rm", params[0] + ": No such file or directory")
		return
		
	if !options.valid:
		
		if obj is DirectoryObject:
			emit_signal("exception_occurred", "rm", params[0] + ": Is a directory")
			return
			
		obj.parent.children.erase(obj)
		
	else:
		if obj.path == terminal.dir_tree.root_path:
			emit_signal("exception_occurred", "rm", "Cannot remove root directory")
			return
			
		obj.parent.children.erase(obj)


func rmdir(params: Array, flags: Array) -> void:
	if flags.size() > 0:
		emit_signal("exception_occurred", "rmdir", "Unknown option: " + flags[0])
		return
		
	if params.empty():
		emit_signal("exception_occurred", "rmdir", "Missing operand")
		return
		
	if params.size() > 1:
		emit_signal("exception_occurred", "rmdir", "Unknown operand: " + params[1])
		return
		
	var dir : TerminalObject = terminal.dir_tree.search(params[0])
	
	if !dir:
		emit_signal("exception_occurred", "rmdir", params[0] + ": No such file or directory")
		return
		
	if dir is FileObject:
		emit_signal("exception_occurred", "rmdir", params[0] + ": Not a directory")
		return
		
	if !dir.children.empty():
		emit_signal("exception_occurred", "rmdir", params[0] + ": Directory not empty")
		return
		
	if dir.path == terminal.dir_tree.root_path:
		emit_signal("exception_occurred", "rmdir", "Cannot remove root directory")
		return
		
	dir.parent.children.erase(dir)


func touch(params: Array, flags: Array) -> void:
	if flags.size() > 0:
		emit_signal("exception_occurred", "touch", "Unknown option: " + flags[0])
		return
		
	if params.empty():
		emit_signal("exception_occurred", "touch", "Missing operand")
		return
		
	if params.size() > 1:
		emit_signal("exception_occurred", "touch", "Unknown operand: " + params[1])
		return
		
	var file_path : String = params[0]
	
	if file_path.ends_with("/") && file_path != terminal.dir_tree.root_path:
		file_path.erase(file_path.length() - 1, 1)
		
	var parent : DirectoryObject = terminal.dir_tree.search(file_path + "/..", true)
	
	if !parent:
		emit_signal("exception_occurred", "touch", "Cannot create file: '" + file_path + "': No such file or directory")
		return
		
	var file_name := file_path.substr(file_path.find_last("/") + 1)
	
	if !file_name.is_valid_filename():
		emit_signal("exception_occurred", "touch", "Cannot create directory: '" + file_path + "': Invalid file name")
		return
		
	var file_exists := false
	
	if file_name == "." || file_name == "..":
		file_exists = true
		
	if !file_exists:
		var new_file_path := parent.path
		
		if new_file_path == terminal.dir_tree.root_path:
			new_file_path += file_name
			
		else:
			new_file_path += "/" + file_name
			
		for child in parent.children:
			
			if child.path == new_file_path:
				file_exists = true
				break
				
	if file_exists:
		emit_signal("exception_occurred", "touch", "Cannot create file: '" + file_path + "': File exists")
		return
		
	var name_ext = Array(file_name.split("."))
	var name : String
	var extension := ""
	
	if name_ext.size() > 1:
		extension = name_ext.pop_back()
		
		if name_ext.size() > 1:
			name = PoolStringArray(name_ext).join(".")
			
		else:
			name = name_ext[0]
			
	else:
		name = name_ext[0]
		
	var new_file : FileObject = terminal.dir_tree.create_file(name, extension, "", parent)
	
	parent.add_child(new_file)

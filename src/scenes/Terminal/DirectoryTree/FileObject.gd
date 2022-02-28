## Provides the needed properties for a TerminalObject to be recognized as a file.
##
## Unlike it's superclass (TerminalObject), a FileObject instance can be contained
## inside a DirectoryObjectTree instance since it's already defined as more than
## just a "generic" object.
class_name FileObject
extends TerminalObject


var name : String setget set_name, get_name
var path : String setget set_path, get_path
var extension : String setget set_extension, get_extension
var content : String setget set_content, get_content
var parent : DirectoryObject setget set_parent, get_parent


func _init(
	file_name: String, file_path: String, file_extension: String,
	file_content: String, parent_dir: DirectoryObject
) -> void:
	
	self.name = file_name
	self.path = file_path
	self.extension = file_extension
	self.content = file_content
	self.parent = parent_dir

## Setters

func set_name(new_name: String) -> void:
	if self.path:
		var new_path := self.path
		
		if self.extension:
			new_path.erase(self.path.find_last("/") + 1, self.name.length())
			new_path = new_path.insert(new_path.find_last("."), new_name)
			
		else:
			new_path.erase(self.path.find_last("/") + 1, self.name.length())
			new_path += new_name
			
		self.path = new_path
	
	name = new_name

func set_path(new_path: String) -> void:
	path = new_path

func set_extension(new_extension: String) -> void:
	if self.extension:
		var new_path := self.path
		
		if new_extension:
			new_path.erase(self.path.find_last(".") + 1, self.extension.length())
			new_path += new_extension
			
		else:
			new_path.erase(self.path.find_last("."), self.extension.length() + 1)
			
		self.path = new_path
		
	extension = new_extension

func set_content(new_content: String) -> void:
	content = new_content

func set_parent(new_parent: DirectoryObject) -> void:
	parent = new_parent

## Getters

func get_name() -> String:
	return name

func get_path() -> String:
	return path

func get_extension() -> String:
	return extension

func get_content() -> String:
	return content

func get_parent() -> DirectoryObject:
	return parent

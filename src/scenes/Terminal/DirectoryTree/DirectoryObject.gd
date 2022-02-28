## Provides the needed properties for a TerminalObject to be recognized as a directory.
##
## Unlike it's superclass (TerminalObject), a DirectoryObject instance can be contained
## inside a DirectoryObjectTree instance since it's already defined as more than
## just a "generic" object.
class_name DirectoryObject
extends TerminalObject


var name : String setget set_name, get_name
var path : String setget set_path, get_path
var parent : DirectoryObject setget set_parent, get_parent
var children := [] setget set_children, get_children


func _init(
	dir_name: String, dir_path: String, dir_children: Array, parent_dir: DirectoryObject
) -> void:
	
	self.name = dir_name
	self.path = dir_path
	self.parent = parent_dir
	self.children = dir_children


func add_child(item: TerminalObject) -> void:
	children.append(item)

## Setters

func set_name(new_name: String) -> void:
	if self.path:
		var new_path := self.path
		
		new_path.erase(self.path.find_last("/") + 1, self.name.length())
		new_path += new_name
		
		self.path = new_path
	
	name = new_name

func set_path(new_path: String) -> void:
	path = new_path

func set_parent(new_parent: DirectoryObject) -> void:
	parent = new_parent

func set_children(new_children: Array) -> void:
	children = new_children

## Getters

func get_name() -> String:
	return name

func get_path() -> String:
	return path

func get_parent() -> DirectoryObject:
	return parent

func get_children() -> Array:
	return children

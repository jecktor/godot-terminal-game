## General n-ary search tree which contains an emulated terminal directory structure.
##
## The tree is capable of containing DirectoryObject and FileObject instances.
## A pre-made tree in Dictionary format can be provided as a parameter
## in the `_init` method: `raw_tree`, it will be automatically parsed
## when an instance is created as long as it follows the proper key/value structure.
class_name DirectoryObjectTree
extends Reference


var root : DirectoryObject
var current_dir : DirectoryObject setget set_current_dir, get_current_dir

var root_path : String
var home_path : String

var parse_error : String


func _init(tree_path := "") -> void:
	var raw_tree := { "children": [{ "children": [], "name": "home" }], "name": "/" }
	
	if tree_path:
		raw_tree = Global.load_json(tree_path)
		
	root = _parse_root(raw_tree)
	
	for child in root.children:
		
		if child.path == home_path:
			current_dir = child
			break
			
	if !current_dir:
		current_dir = root


# Creates a new instace of the DirectoryObject class.
func create_directory(
	name: String, children := [], parent_dir := current_dir
) -> DirectoryObject:
	
	var is_root := !parent_dir && name == root_path
	var path : String
	
	if is_root:
		path = name
		
	else:
		path = create_object_path(parent_dir.path, name)
		
	var new_dir := DirectoryObject.new(name, path, [], parent_dir)
	
	if children.size() > 0:
		_parse_children(new_dir, children)
		
	return new_dir


# Creates a new instace of the FileObject class.
func create_file(
	name: String, extension: String, content := "", parent_dir := current_dir
) -> FileObject:
	
	var path := create_object_path(parent_dir.path, name, extension)
	
	return FileObject.new(name, path, extension, content, parent_dir)


## Creates a unique String path for a DirectoryObject or FileObject instance.
func create_object_path(
	parent_path: String, object_name: String, file_extension := ""
) -> String:
	
	var is_parent_root := parent_path == root_path
	var object_path : String
	
	if is_parent_root:
		object_path = parent_path + object_name
		
	else:
		object_path = parent_path + "/" + object_name
		
	if file_extension:
		object_path += "." + file_extension
		
	return object_path


## Searches the n-ary directory tree level wise using a stack and returns
## an object that matches the provided path, if not found returns null.
func search(path: String, skip_files := false) -> TerminalObject:
	if _is_rel_path(path):
		path = _resolve_path(path)
		
	if path.ends_with("/") && path != "/":
		path.erase(path.length() - 1, 1)
		
	var stack := []
	stack.append(root)
	
	while stack.size() != 0:
		var children_count := stack.size()
		
		while children_count > 0:
			var current_child: TerminalObject = stack[0]
			stack.pop_front()
			
			if current_child is FileObject && skip_files:
				children_count -= 1
				continue
				
			if current_child.path == path:
				return current_child
				
			if current_child is DirectoryObject:
				stack.append_array(current_child.children)
				
			children_count -= 1
			
	return null


## Converts the tree to a Dictionary that can be stored in a JSON file.
func to_dictionary() -> Dictionary:
	var dict_tree := _object_to_dictionary(root)
	
	return dict_tree


## Sorts a DirectoryObject's children alphabetically.
func sort_dir_children(a: TerminalObject, b: TerminalObject) -> bool:
	if a.name < b.name:
		return true
		
	return false


## Updates a DirectoryObject's children path using recursion.
func update_dir_children_path(dir: DirectoryObject) -> void:
	_update_children_path(dir)


## Converts a DirectoryObject or FileObject instance into a Dictionary.
func _object_to_dictionary(
	obj: TerminalObject
) -> Dictionary:
	
	var new_dictionary := {}
	
	if obj is FileObject:
		new_dictionary = { "name": obj.name, "extension": obj.extension, "content": obj.content }
		
	else:
		new_dictionary = { "name": obj.name, "children": [] }
		
		if obj.children.size() > 0:
			_children_to_dictionary(new_dictionary, obj.children)
			
	return new_dictionary


## Converts FileObject or DirectoryObject instance's `children` into a Dictionary
## using a recursion.
func _children_to_dictionary(dict_dir: Dictionary, children: Array) -> void:
	var dict_children := []
	
	for child in children:
		
		if "children" in child:
			dict_children.append(_object_to_dictionary(child))
			
		else:
			dict_children.append(_object_to_dictionary(child))
			
	dict_dir.children = dict_children


## Parses a Dictionary tree into a tree of DirectoryObject or FileObject instances.
func _parse_root(raw_root: Dictionary) -> DirectoryObject:
	if "error" in raw_root:
		parse_error = raw_root.error
		
	elif !raw_root.has("name") || !raw_root.has("children"):
		parse_error = "Tree has no root!"
		
	elif typeof(raw_root.name) != TYPE_STRING || typeof(raw_root.children) != TYPE_ARRAY:
		parse_error = "Invalid tree root!"
		
	elif raw_root.name != "/":
		parse_error = "Invalid root directory name!"
		
	if parse_error:
		raw_root = { "children": [{ "children": [], "name": "home" }], "name": "/" }
		
	root_path = raw_root.name
	home_path = root_path + "home"
	
	return create_directory(raw_root.name, raw_root.children, null)


## Converts FileObject or DirectoryObject instance's `children` into more instances
## of said classes using a recursion.
func _parse_children(dir: DirectoryObject, raw_children: Array) -> void:
	var parsed_children := []
	
	for child in raw_children:
		
		if typeof(child) != TYPE_DICTIONARY:
			parse_error = str(child) + ": Directory child must be a Dictionary!"
			continue
			
		elif !child.has("name"):
			parse_error = str(child) + ": Directory child has no name!"
			continue
			
		elif typeof(child.name) != TYPE_STRING:
			parse_error = str(child) + ": Directory child name must be a String!"
			continue
			
		elif !child.name:
			parse_error = str(child) + ": Directory child name cannot be empty!"
			continue
			
		elif !child.name.is_valid_filename():
			parse_error = str(child) + ": Directory child name is not valid!"
			continue
			
		if "children" in child:
			
			if typeof(child.children) != TYPE_ARRAY:
				parse_error = str(child) + ": Directory children must be an Array!"
				continue
				
			parsed_children.append(create_directory(child.name, child.children, dir))
			
		elif "content" in child && "extension" in child:
			
			if typeof(child.content) != TYPE_STRING:
				parse_error = str(child) + ": File contents should be a String!"
				continue
				
			elif typeof(child.extension) != TYPE_STRING:
				parse_error = str(child) + ": File extension should be a String!"
				continue
				
			elif child.extension && !child.extension.is_valid_filename():
				parse_error = str(child) + ": File extension is not valid!"
				continue
				
			parsed_children.append(create_file(child.name, child.extension, child.content, dir))
			
		else:
			parse_error = str(child) + ": Invalid directory child!"
			
	dir.children = parsed_children


## Updates a DirectoryObject's children path using recursion.
func _update_children_path(dir: DirectoryObject) -> void:
	for child in dir.children:
		
		if child is FileObject:
			child.path = create_object_path(child.parent.path, child.name, child.extension)
			
		else:
			child.path = create_object_path(child.parent.path, child.name)
			
			if child.children.size() > 0:
				update_dir_children_path(child)


## Converts a relative path into an absolute path.
func _resolve_path(path: String, base := current_dir.path) -> String:
	var stack := Array(base.split("/"))
	
	stack.pop_front()
	stack.push_front(root_path)
	
	if !path.ends_with("/"):
		path = path.insert(path.length(), "/")
		
	if path[0] == "~":
		path[0] = home_path
		stack = [root_path]
		
	for dir in path.split("/"):
		if dir:
			
			if dir == ".":
				continue
				
			if dir == "..":
				if stack.size() > 1:
					stack.pop_back()
					
			else:
				stack.append(dir)
				
	var new_path := PoolStringArray(stack).join("/")
	
	if new_path != root_path:
		new_path.erase(0, root_path.length())
		
	if current_dir.path == root_path && new_path != home_path:
		var root_len := root_path.length()
		
		if !home_path + "/" in new_path || new_path.substr(0, root_len * 2) == root_path.repeat(2):
			new_path.erase(root_len, root_len)
			
	return new_path


## Returns true if the provided path is relative.
func _is_rel_path(path: String) -> bool:
	var is_rel := false
	
	if path != root_path:
		
		for dir in path.split("/"):
			
			if dir == "~" || dir == "." || dir == "..":
				is_rel = true
				break
				
		if path[0] != root_path:
			is_rel = true
			
	return is_rel

## Setters

func set_current_dir(new_dir: DirectoryObject) -> void:
	current_dir = new_dir

## Getters

func get_current_dir() -> DirectoryObject:
	return current_dir

extends Node

## Autoload singleton. Central registry for all menus.
## Tracks open/close state, enforces layer blocking, and resolves
## exclusive-group conflicts.
##
## Layer rules:
##   A higher-layer menu being open BLOCKS new opens on lower layers,
##   but does NOT force-close them (pause is a non-destructive overlay).
##
## Group rules:
##   When a menu opens, all currently-open menus whose group is listed
##   in the opener's closes_groups array are force-closed.

signal menu_opened(id: StringName)
signal menu_closed(id: StringName)

enum Layer {
	WORLD = 0,
	SYSTEM = 10,
}

class _Entry:
	var id: StringName
	var layer: int
	var open_fn: Callable
	var close_fn: Callable
	var group: StringName
	var closes_groups: Array[StringName]
	var is_open: bool = false

var _entries: Dictionary = {}


## Register a menu. Call from the owning system's _ready().
## open_fn / close_fn may be empty Callables when the owner drives
## open/close externally via notify_opened / notify_closed.
func register(
		id: StringName,
		layer: int,
		open_fn: Callable,
		close_fn: Callable,
		group: StringName = &"",
		closes_groups: Array[StringName] = []) -> void:
	if _entries.has(id):
		push_warning("MenuManager: '%s' already registered — overwriting." % id)
	var e := _Entry.new()
	e.id = id
	e.layer = layer
	e.open_fn = open_fn
	e.close_fn = close_fn
	e.group = group
	e.closes_groups = closes_groups
	_entries[id] = e


## Open a menu via its registered open_fn.
## Blocked silently if a higher-layer menu is open.
## Closes conflicting groups before opening.
## context is passed to the open_fn when provided (used e.g. to tell which turret to display).
func request_open(id: StringName, context: Variant = null) -> void:
	if not _entries.has(id):
		push_warning("MenuManager: request_open — unknown id '%s'" % id)
		return
	var e: _Entry = _entries[id]
	if _is_blocked_by_higher_layer(e.layer):
		return
	_close_groups(e.closes_groups)
	e.is_open = true
	if e.open_fn.is_valid():
		if context != null:
			e.open_fn.call(context)
		else:
			e.open_fn.call()
	menu_opened.emit(id)


## Close a menu via its registered close_fn.
func request_close(id: StringName) -> void:
	if not _entries.has(id):
		return
	var e: _Entry = _entries[id]
	if not e.is_open:
		return
	e.is_open = false
	if e.close_fn.is_valid():
		e.close_fn.call()
	menu_closed.emit(id)


## For menus opened externally (e.g. ShopManager calling panel.open(args)).
## Enforces group exclusivity and updates state — does NOT call open_fn.
func notify_opened(id: StringName, context: Variant = null) -> void:
	if not _entries.has(id):
		push_warning("MenuManager: notify_opened — unknown id '%s'" % id)
		return
	var e: _Entry = _entries[id]
	if _is_blocked_by_higher_layer(e.layer):
		return
	_close_groups(e.closes_groups)
	e.is_open = true
	menu_opened.emit(id)


## For menus closed externally. Updates state — does NOT call close_fn.
func notify_closed(id: StringName) -> void:
	if not _entries.has(id):
		return
	var e: _Entry = _entries[id]
	if not e.is_open:
		return
	e.is_open = false
	menu_closed.emit(id)


func is_open(id: StringName) -> bool:
	if not _entries.has(id):
		return false
	return (_entries[id] as _Entry).is_open


func _is_blocked_by_higher_layer(layer: int) -> bool:
	for e: _Entry in _entries.values():
		if e.is_open and e.layer > layer:
			return true
	return false


func _close_groups(groups: Array[StringName]) -> void:
	for group in groups:
		if group.is_empty():
			continue
		for e: _Entry in _entries.values():
			if e.is_open and e.group == group:
				e.is_open = false
				if e.close_fn.is_valid():
					e.close_fn.call()
				menu_closed.emit(e.id)

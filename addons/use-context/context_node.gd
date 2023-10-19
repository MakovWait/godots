extends Node

signal updated

const _Context = preload("res://addons/use-context/context.gd")
const _ContextKeys = preload("res://addons/use-context/context_keys.gd")

var _ctx = _Context.new()
var _waiters: Array[ResolveWaiters] = []


func _init():
	updated.connect(func():
		var unresolved: Array[ResolveWaiters] = []
		for w in _waiters:
			w.update(_ctx)
			if w.is_resolved():
				w.resolve()
			else:
				unresolved.append(w)
		_waiters = unresolved
	)


func use_or_null(node: Node, key, default=null):
	var path_from = str(node.get_path())
	var value = _ctx.find(path_from, _cast_key(key))
	return value


func wait_resolved(node: Node, keys, callback: Callable):
	if not keys is Array:
		keys = [keys]
	var waiters_list: Array[ResolveWaiter] = []
	for key in keys:
		waiters_list.append(ResolveWaiterDefault.new(
			str(node.get_path()),
			_cast_key(key)
		))
	_waiters.append(ResolveWaiters.new(
		waiters_list,
		callback
	))


func use(node: Node, key):
	var value = use_or_null(node, key)
	assert(value != null, "Context value was not found")
	return value


func use_or_fallback(node: Node, key, fallback: Callable):
	var value = use_or_null(node, key)
	if value == null:
		return fallback.call()
	else:
		return value


func erase(path, ctx_value):
	if path is Node:
		path = str(path.get_path())
	else:
		path = str(path)
	_erase(path, ctx_value)


func add(path, ctx_value):
	if path is Node:
		path = str(path.get_path()) 
	else:
		path = str(path)
	_add(path, ctx_value)


func sanitize():
	_ctx.sanitize()


func active_waiters_len():
	return len(_waiters)


func _add(path, v):
	_ctx.add(path, v)
	updated.emit()


func _erase(path, v):
	_ctx.erase(path, v)
	updated.emit()


func _cast_key(key):
	if key is Script:
		return _ContextKeys.by_type(key)
	else:
		return key


class ResolveWaiter:
	func update(ctx):
		pass
	
	func is_resolved():
		pass
		
	func value():
		pass


class ResolveWaiterDefault extends ResolveWaiter:
	var _path
	var _key
	
	var _value = null
	
	func _init(path, key):
		_path = path
		_key = key
	
	func update(ctx):
		_value = ctx.find(_path, _key)
	
	func is_resolved():
		return _value != null
	
	func value():
		return _value


class ResolveWaiters:
	var _waiters: Array[ResolveWaiter]
	var _callback: Callable
	
	func _init(waiters: Array[ResolveWaiter], callback):
		_waiters = waiters
		_callback = callback
	
	func update(ctx):
		for w in _waiters:
			if not w.is_resolved():
				w.update(ctx)
	
	func resolve():
		_callback.callv(_waiters.map(func(w: ResolveWaiter): return w.value()))
	
	func is_resolved():
		return _waiters.all(func(w: ResolveWaiter): return w.is_resolved())

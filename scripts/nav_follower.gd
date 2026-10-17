class_name NavFollower
extends RefCounted
## What a walker (enemy, guard) uses to get to a goal around obstacles: direction(from, to, clearance, delta) gives the flat
## unit direction to move. While the straight line to the goal is free on the NavGrid of the region the walker stands in
## (or there is no grid, or no path), that is the direct direction; otherwise it is the direction of the next waypoint of
## a path, found with NavGrid.find_path and followed until the line is free again. Pure: no autoload references.
## Spec: docs/superpowers/specs/2026-10-14-camera-pathfinding-design.md

const CHECK_EVERY := 0.2                   # seconds between the "is the line free" checks
const REPATH_AFTER := 0.6                  # a path is only replaced after this long ...
const GOAL_MOVED := 1.5                    # ... when the goal has moved this far
const NEW_GOAL := 8.0                      # a goal this far from the path's goal means a new path at once
const REACH := 0.7                         # waypoint reached
const STRAY := 3.0                         # farther than this from the path: search again
const NEAR := 2.5                          # closer than this to the goal the way is always direct
const SEARCHES_PER_FRAME := 2

static var _budget_frame := -1
static var _budget_used := 0

var active := false                        # walking a path right now (not straight at the goal)
var _path := PackedVector3Array()
var _index := 0
var _goal := Vector3.INF
var _origin := Vector3.ZERO                # where the current path was searched from
var _age := 0.0
var _check := 0.0
var _clear := true


func reset() -> void:
	active = false
	_path = PackedVector3Array()
	_index = 0
	_goal = Vector3.INF
	_age = 0.0
	_check = 0.0
	_clear = true


func direction(from: Vector3, to: Vector3, clearance: float, delta: float) -> Vector3:
	var straight := Vector3(to.x - from.x, 0.0, to.z - from.z)
	var dist := straight.length()
	if dist < 0.001:
		active = false
		return Vector3.ZERO
	var grid := NavGrid.at(from)
	if grid == null or not grid.is_ready(clearance) or dist < 0.6:
		active = false
		_path = PackedVector3Array()
		return straight / dist
	_check -= delta
	_age += delta
	if _check <= 0.0:
		_check = CHECK_EVERY
		_clear = grid.line_clear(from, to, clearance)
	if _clear:
		active = false
		_path = PackedVector3Array()
		return straight / dist
	# the line is blocked: follow (and when needed make) a path
	var need := _path.is_empty() or _index >= _path.size()
	if not need and _goal.distance_to(to) > NEW_GOAL:       # a different place altogether (a guard turning home)
		need = true
	if not need and _age > REPATH_AFTER and _goal.distance_to(to) > GOAL_MOVED:
		need = true
	if not need and _stray(from) > STRAY:
		need = true
	if need and _take_search():
		_path = grid.find_path(from, to, clearance)
		_origin = from
		_index = 0
		_age = 0.0
		_goal = to
	if _path.is_empty() or _index >= _path.size():
		active = false
		return straight / dist
	while _index < _path.size() - 1 and Vector2(_path[_index].x - from.x, _path[_index].z - from.z).length() < REACH:
		_index += 1
	var way := Vector3(_path[_index].x - from.x, 0.0, _path[_index].z - from.z)
	if way.length() < 0.05:
		active = false
		return straight / dist
	active = true
	return way.normalized()


## Distance from the walker to the path it follows (the polyline from where the search started through the waypoints).
func _stray(from: Vector3) -> float:
	var best := INF
	var prev := _origin
	var p2 := Vector2(from.x, from.z)
	for w in _path:
		var a := Vector2(prev.x, prev.z)
		var b := Vector2(w.x, w.z)
		var ab := b - a
		var len2 := ab.length_squared()
		var t := 0.0 if len2 <= 0.000001 else clampf((p2 - a).dot(ab) / len2, 0.0, 1.0)
		best = minf(best, (a + ab * t).distance_to(p2))
		prev = w
	return best


## At most SEARCHES_PER_FRAME path searches per physics frame over all walkers: a crowd takes turns.
static func _take_search() -> bool:
	var frame := Engine.get_physics_frames()
	if frame != _budget_frame:
		_budget_frame = frame
		_budget_used = 0
	if _budget_used >= SEARCHES_PER_FRAME:
		return false
	_budget_used += 1
	return true

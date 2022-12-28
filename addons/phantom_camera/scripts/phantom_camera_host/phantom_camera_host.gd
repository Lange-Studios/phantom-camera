@tool
class_name PhantomCameraHost
extends Node
@icon("res://addons/phantom_camera/icons/PhantomCameraHostIcon.svg")

const PhantomCameraGroupNames = preload("res://addons/phantom_camera/scripts/group_names.gd")

###########
# Variables
###########
#  General Variables
var _active_phantom_camera_priority: int = -1
var _active_cam_missing: bool

# Tweening Variables
var _phantom_camera_tween: Tween
var _tween_default_ease: Tween.EaseType
var _easing: Tween.TransitionType


var camera: Node
var _active_phantom_camera: Node
var _phantom_camera_list: Array[Node]

var _previous_active_phantom_camera_position
var _previous_active_phantom_camera_rotation

var should_tween: bool
var tween_duration: float

var multiple_phantom_camera_hosts: bool
var phantom_camera_host_group: Array[Node]


###################
# Private Functions
###################
func _enter_tree() -> void:
	camera = get_parent()

	if camera is Camera3D or camera is Camera2D:
		add_to_group(PhantomCameraGroupNames.PHANTOM_CAMERA_HOST_GROUP_NAME)
#		var already_multi_hosts: bool = multiple_phantom_camera_hosts

		_check_camera_host_amount()

		if multiple_phantom_camera_hosts:
			printerr(
				"Only one PhantomCameraHost can exist in a scene",
				"\n",
				"Multiple PhantomCameraHosts will be supported in https://github.com/MarcusSkov/phantom-camera/issues/26"
			)
			queue_free()

		var phantom_camera_group_nodes: Array[Node] = get_tree().get_nodes_in_group(PhantomCameraGroupNames.PHANTOM_CAMERA_GROUP_NAME)
		for phantom_camera in phantom_camera_group_nodes:
			if not multiple_phantom_camera_hosts:

				phantom_camera_added_to_scene(phantom_camera)
				phantom_camera.assign_phantom_camera_host()
#			else:
#				phantom_camera.Properties.check_multiple_phantom_camera_host_property(phantom_camera, phantom_camera_host_group, true)
	else:
		printerr("PhantomCameraHost is not a child of a Camera")


func _exit_tree() -> void:
	remove_from_group(PhantomCameraGroupNames.PHANTOM_CAMERA_HOST_GROUP_NAME)
	_check_camera_host_amount()

	var phantom_camera_group_nodes: Array[Node] = get_tree().get_nodes_in_group(PhantomCameraGroupNames.PHANTOM_CAMERA_GROUP_NAME)
	for phantom_camera in phantom_camera_group_nodes:
		if not multiple_phantom_camera_hosts:
			phantom_camera.Properties.check_multiple_phantom_camera_host_property(phantom_camera)


func _check_camera_host_amount():
	phantom_camera_host_group = get_tree().get_nodes_in_group(PhantomCameraGroupNames.PHANTOM_CAMERA_HOST_GROUP_NAME)
	if phantom_camera_host_group.size() > 1:
		multiple_phantom_camera_hosts = true
	else:
		multiple_phantom_camera_hosts = false


func _assign_new_active_phantom_camera(phantom_camera: Node) -> void:
	var no_previous_pcam: bool

	if _active_phantom_camera:
		_previous_active_phantom_camera_position = camera.get_position()
		_previous_active_phantom_camera_rotation = camera.get_rotation()
	else:
		no_previous_pcam = true

	_active_phantom_camera = phantom_camera
	_active_phantom_camera_priority = phantom_camera.get_priority()

	if no_previous_pcam:
		_previous_active_phantom_camera_position = _active_phantom_camera.get_position()
		_previous_active_phantom_camera_rotation = _active_phantom_camera.get_rotation()

	tween_duration = 0
	should_tween = true


func _find_phantom_camera_with_highest_priority(should_animate: bool = true) -> void:
#	if _phantom_camera_list.is_empty(): return
	for phantom_camera in _phantom_camera_list:
		if phantom_camera.get_priority() > _active_phantom_camera_priority:
			_assign_new_active_phantom_camera(phantom_camera)

		_active_cam_missing = false


func _move_target(delta: float) -> void:
	tween_duration += delta
	camera.set_position(
		Tween.interpolate_value(
			_previous_active_phantom_camera_position, \
			_active_phantom_camera.get_global_position() - _previous_active_phantom_camera_position,
			tween_duration, \
			_active_phantom_camera.get_tween_duration(), \
			_active_phantom_camera.get_tween_transition(),
			Tween.EASE_IN_OUT
		)
	)
	camera.set_rotation(
		Tween.interpolate_value(
			_previous_active_phantom_camera_rotation, \
			_active_phantom_camera.get_global_rotation() - _previous_active_phantom_camera_rotation,
			tween_duration, \
			_active_phantom_camera.get_tween_duration(), \
			_active_phantom_camera.get_tween_transition(),
			Tween.EASE_IN_OUT
		)
	)


func _process(delta: float) -> void:
	if _active_cam_missing: return

#	print(_active_phantom_camera.get_priority())

	if not should_tween:
		if camera is Camera3D:
			camera.set_position(_active_phantom_camera.get_global_position())
			camera.set_rotation(_active_phantom_camera.get_global_rotation())
		elif camera is Camera2D:
			camera.set_global_position(_active_phantom_camera.get_global_position())
			camera.set_global_rotation(_active_phantom_camera.get_global_rotation())
	else:
		if tween_duration < _active_phantom_camera.get_tween_duration():
			_move_target(delta)
		else:
#			TODO Logic for having different follow / look at options
			tween_duration = 0
			should_tween = false


##################
# Public Functions
##################
func phantom_camera_added_to_scene(phantom_camera: Node) -> void:
	_phantom_camera_list.append(phantom_camera)
	_find_phantom_camera_with_highest_priority(false)


func phantom_camera_removed_from_scene(phantom_camera) -> void:
	_phantom_camera_list.erase(phantom_camera)
	if phantom_camera == _active_phantom_camera:
		_active_cam_missing = true
		_active_phantom_camera_priority = -1
		_find_phantom_camera_with_highest_priority()


func phantom_camera_priority_updated(phantom_camera: Node) -> void:
	var current_pcam_priority: int = phantom_camera.get_priority()

	if current_pcam_priority >= _active_phantom_camera_priority and phantom_camera != _active_phantom_camera:
		_assign_new_active_phantom_camera(phantom_camera)
	elif phantom_camera == _active_phantom_camera:
		if current_pcam_priority <= _active_phantom_camera_priority:
			_active_phantom_camera_priority = current_pcam_priority
			_find_phantom_camera_with_highest_priority()
		else:
			_active_phantom_camera_priority = current_pcam_priority

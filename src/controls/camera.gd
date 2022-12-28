extends MeshInstance3D

@export var rot_spd := 0.15
@export var pan_spd := 0.25

@onready var tilemap  = get_parent() 
@onready var ray_cast = get_node('../ray') 
@onready var camera   = get_node('camera') 
@onready var viewport = get_node('../../../VP') 
const MOVE_MARGIN = 20
const MOVE_SPEED = 20
var tile_pos   := Vector3.ZERO
var last_pos   := Vector3.ZERO
var _pos       := Vector3.ZERO
var _rot       := Vector3(-45, 45, 0)
var is_motion  := false
var is_draw    := false
var is_erase   := false
var is_rot     := false
var is_pan     := false
var can_draw   := false
var ray_length := 10000


func _ready() -> void:
	G.camera = self
	match G.mode:
		G.EDIT_MODE:
			_init_edit_mode()
		G.GAME_MODE:
			_init_game_mode()
#END

func _init_edit_mode() -> void:	
	position.y = tilemap.level * tilemap.height
	_rot = rotation_degrees
	_pos = position
	can_draw = true
#END

func _init_game_mode() -> void:
	pass
#END

#func raycast_from_mouse(collision_mask):
#	var ray_start: Vector3 = cam.project_ray_origin(m_pos)
#	var ray_end: Vector3 = ray_start + cam.project_ray_normal(m_pos) * ray_length
#	var space_state = get_world_3d().direct_space_state
#	var prqp := PhysicsRayQueryParameters3D.new()
#	prqp.from = ray_start
#	prqp.to = ray_end
#	prqp.collide_with_areas = collision_mask
#	prqp.exclude = []
#	return space_state.intersect_ray(prqp)

func _physics_process(delta: float) -> void:
	if G.mode == G.EDIT_MODE: # Level Editor Mode
		if !is_rot && !is_pan:
			var mouse = get_viewport().get_mouse_position()
			var from = camera.project_ray_origin(mouse)
			var to = from + camera.project_ray_normal(mouse) * ray_length
			
			ray_cast.target_position = to
			ray_cast.position = from
		if can_draw:
			print(ray_cast.is_colliding())
			if ray_cast.is_colliding() && (!is_rot && !is_pan):
				print("OK")
				var _pos = ray_cast.get_collision_point().floor()
				_pos.y = tilemap.level * tilemap.height
				_pos.x += 0.5
				_pos.z += 0.5
				tile_pos = _pos + Vector3(tilemap._size/2 - 0.5, 0, tilemap._size/2 - 0.5)
				tilemap.ray_is_colliding()
			else:
				tilemap.ray_not_colliding()
		#ON tile mouse enter
		if last_pos != tile_pos:
			print("ENTER")
			tilemap._on_tile_mouse_enter()
			last_pos = tile_pos
#		if is_motion:
#			tilemap.view_gizmo.rotation_degrees = rotation_degrees
	else: # Game Mode
		var axis = get_input_axis()
		_pos -= ((transform.basis.z - transform.basis.y) * axis.y + transform.basis.x * axis.x) * 0.2
		_pos.x = clamp(_pos.x, -tilemap._size/2, tilemap._size/2)
		_pos.z = clamp(_pos.z, -tilemap._size/2, tilemap._size/2)

	# code for both game and level editor
	if !_pos.is_equal_approx(position):
		position += (_pos - position) * pan_spd
	if !_rot.is_equal_approx(rotation_degrees):
		rotation_degrees.y += (_rot.y - rotation_degrees.y) * rot_spd
		rotation_degrees.x += (_rot.x - rotation_degrees.x) * rot_spd
	var axis = move_by_viewport_margin()
	if axis != Vector3.ZERO:
		_pos -= ((transform.basis.z - transform.basis.y) * axis.y + transform.basis.x * axis.x) * 0.2
		_pos.y = 0

#END

func move_by_viewport_margin():
	var m_pos = get_viewport().get_mouse_position()
	var v_size = get_viewport().size
	var move_vec = Vector3.ZERO
	if m_pos.x < MOVE_MARGIN:
		move_vec.x += 1
	if m_pos.y < MOVE_MARGIN:
		move_vec.y += 1
	if m_pos.x > v_size.x - MOVE_MARGIN:
		move_vec.x -= 1
	if m_pos.y > v_size.y - MOVE_MARGIN:
		move_vec.y -= 1
	
	return move_vec

func get_input_axis() -> Vector2:
	var _axis = Vector2.ZERO
	_axis.x = int(Input.get_action_strength('a')) - int(Input.get_action_strength('d'))
	_axis.y = int(Input.get_action_strength('w')) - int(Input.get_action_strength('s'))
	if _axis.length() > 1:
		_axis = _axis.normalized()
	return _axis


func _input(event: InputEvent) -> void:
	if G.mode == G.EDIT_MODE:
		if !event is InputEventMouseButton && !event is InputEventMouseMotion:
			return
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT && (can_draw && !is_erase):
				if event.is_pressed():
					if can_draw && (!is_rot && !is_pan):
						is_draw = true
						tilemap._on_left_pressed()
				else:
					if is_draw:
						is_draw = false
						tilemap._on_left_released()

			if event.button_index == MOUSE_BUTTON_RIGHT && (can_draw && !is_draw):
				if event.is_pressed():
					if can_draw && (!is_rot && !is_pan):
							is_erase = true
							tilemap._on_right_pressed()
				else:
					if is_erase:
						is_erase = false
						tilemap._on_right_released()

			if ( (!is_draw && !is_erase) && (!is_rot && !is_pan) ):
				if event.button_index == MOUSE_BUTTON_WHEEL_UP || event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					if event.button_index == MOUSE_BUTTON_WHEEL_UP && camera.position.z > 3:
						camera.position.z -= 1
					if event.button_index == MOUSE_BUTTON_WHEEL_DOWN && camera.position.z < 40:
						camera.position.z += 1
			if event.button_index == MOUSE_BUTTON_MIDDLE && (!is_draw && !is_erase):
				if event.is_pressed():
					tilemap.tile_ind.hide()
					can_draw = false
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
					if !G.shift_pr:
						is_rot = true
					else:
						is_pan = true
				else:
					can_draw = true
					is_rot = false
					is_pan = false
					tilemap.tile_ind.visible = true if can_draw else false
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if event is InputEventMouseMotion:
			is_motion = true
			var _motion = event.relative
			if is_pan:
				_pos -= ((transform.basis.z - transform.basis.y) * _motion.y + transform.basis.x * _motion.x) * 0.01
				_pos.x = clamp(_pos.x, -tilemap._size/2, tilemap._size/2)
				_pos.z = clamp(_pos.z, -tilemap._size/2, tilemap._size/2)
				_pos.y = tilemap.level * tilemap.height
			if is_rot:
				_rot.y -= _motion.x * rot_spd
				_rot.x -= _motion.y * rot_spd
				_rot.x = clamp(_rot.x, -90, 90)
		else:
			is_motion = false
#END

extends Node

const GAME_MODE = 0
const EDIT_MODE = 1

var shift_pr = false
var mode = EDIT_MODE
@onready var tilemap : Node3D
@onready var camera : MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

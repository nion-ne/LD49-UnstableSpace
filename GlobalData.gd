extends Node2D


const BUILDER_SHIP = preload("res://scenes/ships/BuilderShip.tscn")
const BUILDER_SHIP_BUILD_TIME = 3.0 # 45
const BUILDER_SHIP_METAL_COST = 50
const BUILDER_SHIP_ENERGY_COST = 50
const BUILDER_SHIP_SPEED = 1
const BUILDER_HEALTH = 100

const SCOUT_SHIP = preload("res://scenes/ships/ScoutShip.tscn")
const SCOUT_SHIP_BUILD_TIME = 3.0 # 15
const SCOUT_SHIP_METAL_COST = 50
const SCOUT_SHIP_ENERGY_COST = 50
const SCOUT_SHIP_SPEED = 2
const SCOUT_HEALTH = 75

const COMBAT_SHIP = preload("res://scenes/ships/FighterShip.tscn")
const COMBAT_SHIP_BUILD_TIME = 3.0 #28
const COMBAT_SHIP_METAL_COST = 50
const COMBAT_SHIP_ENERGY_COST = 50
const COMBAT_SHIP_SPEED = 1
const COMBAT_HEALTH = 100
const COMBAT_COOLDOWN = 2.0

const MISSILE = preload("res://scenes/ships/Missile.tscn")
const MISSILE_SPEED = 1
const MISSILE_DAMAGE = 10

const MINE_BUILD_TIME = 3 #25
const MINE_METAL_COST = 50
const MINE_ENERGY_COST = 50
const MINE_RATE = 1

const SOLAR_BUILD_TIME = 3 #25
const SOLAR_METAL_COST = 50
const SOLAR_ENERGY_COST = 50
const SOLAR_RATE = 1

const WARP_SPEED_NORMAL = 20
const WARP_SPEED_SCOUT = 10

const AI_CONTROLLER = preload("res://scenes/AI/EnemyController.tscn")
const AI_DECISION_TIME = 5

export(Curve) var BRIGHTNESS_CURVE = Curve.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



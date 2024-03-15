extends CharacterBody2D

class_name BaseEnemy

@export var mov_speed = 80.0
@export var hp = 10
@export var knock_back_recovery = 3.5
@export var max_coins = 6
@export var money = 2
@export var enemy_damage = 1
var knock_back = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")
@onready var collision = $CollisionEnemy
@onready var hitbox = $EnemyBody/HitBox
@onready var sprite = $EnemyBody/AnimatedSprite2D
@onready var hideTimer = $EnemyBody/HideTimer
@onready var hurtbox = $EnemyBody/HurtBox
@onready var sound = $EnemyBody/hurt_sound

var death = preload("res://scenes/Enemy/death.tscn")
var coins = preload("res://scenes/Loot/Coin.tscn")

signal remove_from_array(object)

var screen_size

func _ready():
	hitbox.damage = enemy_damage
	screen_size = get_viewport_rect().size
	hurtbox.connect("hurt", Callable(self, "_on_hurt_box_hurt"))
	hideTimer.connect("timeout", Callable(self, "_on_hide_timer_timeout"))
	death.connect("finished", Callable(self,"_on"))

func _physics_process(_delta):
	knock_back = knock_back.move_toward(Vector2.ZERO, knock_back_recovery)
	var direction = global_position.direction_to(player.global_position)
	if direction.x > 0.1:
		sprite.flip_h = true
	elif direction.x < -0.1:
		sprite.flip_h = false
		
	if direction != Vector2.ZERO:
		sprite.play("walk")
	velocity = direction*mov_speed
	velocity += knock_back
	move_and_slide()

func _on_hurt_box_hurt(damage, angle, knock_back_amount):
	hp -= damage
	knock_back = angle*knock_back_amount
	if hp <= 0:
		var enemy_death = death.instantiate()
		enemy_death.global_position = global_position
		get_parent().call_deferred("add_child", enemy_death)
		emit_signal("remove_from_array", self)
		var num_coins = randi() % int(max_coins) + 1
		for i in range(num_coins):
			var new_coin = coins.instantiate()
			new_coin.global_position = global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60))
			new_coin.money = money
			loot_base.call_deferred("add_child", new_coin)
		queue_free()
	else:
		sound.play()

func _on_hide_timer_timeout():
	var loc_dif = global_position - player.global_position
	if abs(loc_dif.x) > (screen_size.x/2) * 1.4 || abs(loc_dif.y) > (screen_size.y/2) * 1.4:
		visible = false
	else:
		visible = true

func frame_save(amount = 20):
	var rand_disable = randi() % 100
	if rand_disable < amount:
		collision.call_deferred("set", "disabled", true)
		sprite.stop()
	
func increase_hp():
	hp *= 2

extends Control

@onready var score_label = $MenuContainer/MainLayout/Header/Stats/Score
@onready var rps_label = $MenuContainer/MainLayout/Header/Stats/RPS
@onready var shop_list = $MenuContainer/MainLayout/Columns/LeftCol/ShopScroll/ShopList
@onready var upgrade_grid = $MenuContainer/MainLayout/Columns/RightCol/UpgradeScroll/UpgradeGrid

const BUILDING_ITEM = preload("res://building_item.tscn")
const UPGRADE_ITEM = preload("res://upgrade_item.tscn")

func _ready() -> void:
	GameManager.funds_changed.connect(_on_funds_changed)
	GameManager.rps_changed.connect(_on_rps_changed)
	_on_funds_changed(GameManager.funds)
	_on_rps_changed(GameManager.rps)
	populate_shop()
	check_for_new_upgrades()

func _on_funds_changed(new_funds: float) -> void:
	# Use floor to keep it looking clean, or format as currency
	score_label.text = "$ " + str(floor(new_funds))
	check_for_new_upgrades() # Check as funds increase

func _on_rps_changed(new_rps: float) -> void:
	rps_label.text = "Revenue: $" + str(new_rps) + "/s"

func populate_shop() -> void:
	# Clear existing
	for child in shop_list.get_children():
		child.queue_free()
		
	for id in GameManager.building_order:
		var item = BUILDING_ITEM.instantiate()
		shop_list.add_child(item)
		item.setup(id)

func check_for_new_upgrades() -> void:
	# This is a naive implementation that checks all upgrades every time.
	# Optimized approach would use signals or events.
	
	# Get list of currently displayed upgrades to avoid duplicates
	var displayed_ids = []
	for child in upgrade_grid.get_children():
		if child is Button and "upgrade_id" in child:
			displayed_ids.append(child.upgrade_id)
			
	for id in GameManager.upgrades:
		if GameManager.purchased_upgrades.has(id):
			continue # Already bought
			
		if id in displayed_ids:
			continue # Already shown
			
		if is_upgrade_unlocked(id):
			add_upgrade_to_grid(id)

func is_upgrade_unlocked(id: String) -> bool:
	var u = GameManager.upgrades[id]
	# Unlock logic based on Trigger Type
	if u.type == "building":
		# Trigger value is building count
		if GameManager.buildings.has(u.target):
			return GameManager.buildings[u.target].count >= u.trigger_value
	elif u.type == "global" and u.target == "fund":
		# Trigger value is total funds (or current funds for simplicity)
		return GameManager.funds >= u.trigger_value * 0.5 # Unlock when you have 50% of cost roughly? 
		# Or usually unlocks when you reach the milestone. Let's say unlocked if you can afford it / 2?
		# Actually, standard is unlock when you meet the requirement.
		# For "fund" type, let's assume trigger_value matches the cost roughly or a milestone.
		# Let's say: Unlocks if you have *ever* reached 50% of its cost (simulated by current funds for now)
		return GameManager.funds >= u.cost * 0.1 
	elif u.type == "click":
		# Trigger value is clicks. We don't track total clicks yet.
		# For V1, let's unlock click upgrades based on funds too, or manually pressed count?
		# We need a manual click counter in GameManager.
		# For now, let's just use funds > cost * 0.1
		return GameManager.funds >= u.cost * 0.1
		
	return false

func add_upgrade_to_grid(id: String) -> void:
	var item = UPGRADE_ITEM.instantiate()
	upgrade_grid.add_child(item)
	item.setup(id)

func add_to_score() -> void:
	$SoundFX.play()
	GameManager.add_funds(1.0) # Manual click value
	
func quit_game() -> void:
	GameManager.save_game()
	get_tree().quit()

func load_game() -> void:

	GameManager.load_game()



func new_game() -> void:

	GameManager.reset_game()

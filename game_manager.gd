extends Node

signal funds_changed(new_funds: float)
signal rps_changed(new_rps: float) # Revenue Per Second

var funds: float = 0.0:
	set(value):
		funds = value
		funds_changed.emit(funds)

var rps: float = 0.0:
	set(value):
		rps = value
		rps_changed.emit(rps)

var buildings = {}
var building_order = []
var upgrades = {}
var purchased_upgrades = {}
var global_multiplier = 1.0
var click_multiplier = 1.0

var SAVE_PATH = 'user://savegame.save'

func _ready() -> void:
	load_building_data()
	load_upgrade_data()
	
	# Start the passive income timer
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.timeout.connect(_on_tick)
	timer.start()

func load_building_data() -> void:
	# Base stats for standard Cookie Clicker progression
	# ... (existing code) ...
	var base_costs = [15, 100, 1100, 12000, 130000, 1400000, 20000000, 330000000]
	var base_rps = [0.1, 1.0, 8.0, 47.0, 260.0, 1400.0, 7800.0, 44000.0]
	
	var file = FileAccess.open("res://data/building-categories.csv", FileAccess.READ)
	if not file:
		printerr("Could not open building data!")
		return
		
	# Skip header
	file.get_line()
	
	var index = 0
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 3: continue
		
		var id = line[0] # Tier
		var internal_name = line[1] # Cookie Clicker Name
		var display_name = line[2] # Pharma Equivalent
		var description = line[3] # Role
		
		# Assign stats or generate if we run out of manual base values
		var cost = base_costs[index] if index < base_costs.size() else pow(10, index + 1) * 1.5
		var income = base_rps[index] if index < base_rps.size() else pow(10, index) * 0.8
		
		buildings[id] = {
			"name": display_name,
			"cc_name": internal_name,
			"desc": description,
			"cost": cost,
			"base_rps": income,
			"count": 0,
			"multiplier": 1.0
		}
		building_order.append(id)
		index += 1

func load_upgrade_data() -> void:
	var file = FileAccess.open("res://data/upgrades.csv", FileAccess.READ)
	if not file:
		printerr("Could not open upgrade data!")
		return

	# Skip header
	file.get_line()

	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 8: continue
		
		var id = line[0]
		upgrades[id] = {
			"name": line[1],
			"desc": line[2],
			"cost": float(line[3]),
			"type": line[4], # click, building, global
			"target": line[5], # "click", building_id, "fund"
			"trigger_value": float(line[6]),
			"multiplier": float(line[7])
		}

func _on_tick() -> void:
	funds += rps

func add_funds(amount: float) -> void:
	funds += amount * click_multiplier

func buy_building(id: String) -> bool:
	var b = buildings[id]
	var current_cost = get_building_cost(id)
	
	if funds >= current_cost:
		funds -= current_cost
		b.count += 1
		recalculate_rps()
		return true
	return false

func buy_upgrade(id: String) -> bool:
	if purchased_upgrades.has(id):
		return false
		
	var u = upgrades[id]
	if funds >= u.cost:
		funds -= u.cost
		purchased_upgrades[id] = true
		apply_upgrade_effect(id)
		recalculate_rps()
		return true
	return false

func apply_upgrade_effect(id: String) -> void:
	var u = upgrades[id]
	if u.type == "building":
		# The target in CSV is likely just the tier number (e.g., "1"), 
		# but our buildings dict keys are also just the tier number string (e.g., "1").
		# We need to ensure we match them correctly.
		if buildings.has(u.target):
			buildings[u.target].multiplier *= u.multiplier
	elif u.type == "global":
		global_multiplier *= u.multiplier
	elif u.type == "click":
		click_multiplier *= u.multiplier

func get_building_cost(id: String) -> float:
	var b = buildings[id]
	return b.cost * pow(1.15, b.count)

func recalculate_rps() -> void:
	var total = 0.0
	for id in buildings:
		var b = buildings[id]
		# Base * Count * Building Multipliers
		total += b.count * b.base_rps * b.multiplier
	
	# Apply Global Multiplier
	rps = total * global_multiplier

func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var data = {
		"funds": funds,
		"buildings": {},
		"purchased_upgrades": purchased_upgrades
	}
	for id in buildings:
		data.buildings[id] = buildings[id].count
	file.store_var(data)
	file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = file.get_var()
	file.close()
	
	if data:
		if data.has("funds"):
			funds = data.funds
		if data.has("buildings"):
			for id in data.buildings:
				if buildings.has(id):
					buildings[id].count = data.buildings[id]
		if data.has("purchased_upgrades"):
			purchased_upgrades = data.purchased_upgrades
			# Re-apply effects for loaded upgrades
			# Reset multipliers first to avoid compounding errors on multiple loads
			global_multiplier = 1.0
			click_multiplier = 1.0
			for id in buildings:
				buildings[id].multiplier = 1.0
				
			for id in purchased_upgrades:
				apply_upgrade_effect(id)
				
		recalculate_rps()

func reset_game() -> void:
	funds = 0.0
	global_multiplier = 1.0
	click_multiplier = 1.0
	purchased_upgrades.clear()
	for id in buildings:
		buildings[id].count = 0
		buildings[id].multiplier = 1.0
	recalculate_rps()
	if FileAccess.file_exists(SAVE_PATH):
		pass

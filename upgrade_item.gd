extends Button

var upgrade_id: String

func setup(id: String) -> void:
	upgrade_id = id
	var u = GameManager.upgrades[id]
	text = u.name + "\n$" + str(u.cost)
	tooltip_text = u.desc
	
	GameManager.funds_changed.connect(_on_funds_changed)
	_on_funds_changed(GameManager.funds)

func _on_funds_changed(_funds: float) -> void:
	var u = GameManager.upgrades[upgrade_id]
	disabled = GameManager.funds < u.cost

func _on_pressed() -> void:
	if GameManager.buy_upgrade(upgrade_id):
		queue_free() # Remove from list once bought

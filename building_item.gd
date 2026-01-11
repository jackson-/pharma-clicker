extends HBoxContainer

var building_id: String

func setup(id: String) -> void:
	building_id = id
	update_display()
	GameManager.funds_changed.connect(_on_funds_changed)

func update_display() -> void:
	var b = GameManager.buildings[building_id]
	$Name.text = b.name
	$Name.tooltip_text = b.desc
	$Cost.text = "$" + str(floor(GameManager.get_building_cost(building_id)))
	$Count.text = "x" + str(b.count)
	$BuyButton.disabled = GameManager.funds < GameManager.get_building_cost(building_id)

func _on_funds_changed(_funds: float) -> void:
	update_display()

func _on_buy_button_pressed() -> void:
	if GameManager.buy_building(building_id):
		update_display()

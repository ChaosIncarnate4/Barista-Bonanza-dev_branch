extends Node2D

# Coffee types, their recipes, and initial preparation time
var coffee_types = {
	"Espresso": ["Espresso"],
	"Double Espresso": ["Espresso", "Espresso"],
	"Red Eye": ["Espresso", "Brewed Coffee"],
	"Black Eye": ["Espresso", "Espresso", "Brewed Coffee"],
	"Americano": ["Espresso", "Water"],
	"Long Black": ["Espresso", "Water"],
	"Macchiato": ["Espresso", "Foamed Milk"],
	"Long Macchiato": ["Espresso", "Foamed Milk", "Foamed Milk"],
	"Cortado": ["Espresso", "Warm Milk"],
	"Breve": ["Espresso", "Milk", "Cream"],
	"Cappuccino": ["Espresso", "Steamed Milk", "Milk Foam"],
	"Flat White": ["Espresso", "Steamed Milk", "Microfoam"],
	"Cafe Latte": ["Espresso", "Steamed Milk", "Milk Foam"],
	"Mocha": ["Espresso", "Steamed Milk", "Milk Foam", "Chocolate"],
	"Vienna": ["Espresso", "Whipped Cream"],
	"Affogato": ["Vanilla Gelato", "Espresso"],
	"Cafe au Lait": ["Espresso", "Steamed Milk"],
	"Brewed Coffee": ["Brewed Coffee"],
	"Iced Coffee": ["Brewed Coffee", "Ice"]
}
var customer_names = ["Alice", "Bob", "Charlie", "David", "Eva", "Frank", "Grace", "Henry", "Ivy", "Jack"]

# Ingredients currently added to the coffee
var current_recipe : Array = []

# Level system
var current_level : int = 1
var level_time_multiplier : float = 0.9  # Adjust this multiplier to increase or decrease difficulty
var orders_per_level : int = 2

# Orders display
var orders_label : Label

# Queue to manage multiple orders
var orders_queue: Array = []

# New variables for GUI elements, customer satisfaction, and rewards
var customer_satisfaction : Dictionary = {}
var ingredient_buttons : Dictionary = {}
var currency : int = 0

func _ready():
	# Initialize the orders display and GUI elements
	print("Scene is ready!")
	orders_label = Label.new()
	orders_label.text = "Orders:\n"
	orders_label.modulate = Color(0, 0, 0)  # Set the text color to black
	add_child(orders_label)
	prepare_next_coffee()
	initialize_GUI_elements()

func _process(delta):
	# Check if the timer is active, update orders display, and customer satisfaction
	for coffee_order in orders_queue:
		if coffee_order.timer > 0.0:
			coffee_order.timer -= delta
			update_customer_satisfaction(coffee_order, delta)
			if coffee_order.timer <= 0.0:
				print("Time's up! Serve the next coffee.")
				prepare_next_coffee()

	update_orders_display()
	
func get_ingredients_for_current_level() -> Array:
	var level_coffee_types = get_ordered_complex_coffee_list(current_level)
	var level_ingredients = []
	for coffee_type in level_coffee_types:
		var ingredients = coffee_types[coffee_type]
		for ingredient in ingredients:
			if ingredient not in level_ingredients:
				level_ingredients.append(ingredient)
	return level_ingredients


func initialize_GUI_elements():
	# Clear existing ingredient buttons if any
	for button in ingredient_buttons.values():
		button.queue_free()
	ingredient_buttons.clear()

	# Get ingredients for the current level
	var level_ingredients = get_ingredients_for_current_level()
	
	var screen_width = get_viewport_rect().size.x
	var button_width = 120
	var total_buttons_width = button_width * level_ingredients.size()
	var spacing = (screen_width - total_buttons_width) / (level_ingredients.size() + 1)
	var startPos = Vector2(spacing, get_viewport_rect().size.y - 100)  # Adjust Y position

	# Create buttons for each ingredient in the current level
	for i in range(level_ingredients.size()):
		var ingredient = level_ingredients[i]
		var button = Button.new()
		button.text = ingredient
		button.custom_minimum_size = Vector2(120, 40)
		button.position = startPos + Vector2(spacing * i + button_width * i, 0)
		button.connect("pressed", self._on_ingredient_button_pressed.bind(button))
		add_child(button)
		ingredient_buttons[ingredient] = button


	# Additional setup for "Serve Order" and "Clear Recipe" buttons...
	# Create and setup "Serve Order" button
	var serve_order_button = Button.new()
	var serve_texture = preload("res://Assets/Buttons/ServeCoffeeButton.png")
	serve_order_button.icon = serve_texture
	serve_order_button.text = ""
	serve_order_button.position = Vector2(10, get_viewport_rect().size.y - 300)  # Adjust position as needed
	serve_order_button.connect("pressed", self._on_serve_order_pressed)
	add_child(serve_order_button)

	# Create and setup "Clear Recipe" button
	var clear_recipe_button = Button.new()
	var texture = preload("res://Assets/Buttons/ResetCoffeeButton.png")  # Load your icon texture
	clear_recipe_button.icon = texture  # Set the texture for the button icon
	clear_recipe_button.text = ""
	clear_recipe_button.position = Vector2(200, get_viewport_rect().size.y - 300)  # Adjust position as needed
	clear_recipe_button.connect("pressed", self._on_clear_recipe_pressed)
	add_child(clear_recipe_button)

func _on_ingredient_button_pressed(button: Button):
	# Use the button directly to get the ingredient
	var ingredient = button.text
	add_ingredient(ingredient)

func _on_serve_order_pressed():
	# Clone and sort the current recipe for comparison
	var sorted_current_recipe = current_recipe.duplicate()
	sorted_current_recipe.sort()

	# Attempt to serve the current recipe
	for coffee_order in orders_queue:
		# Clone and sort the recipe from the order for comparison
		var sorted_coffee_order_recipe = coffee_order["recipe"].duplicate()
		sorted_coffee_order_recipe.sort()
		
		if sorted_coffee_order_recipe == sorted_current_recipe:
			serve_order(coffee_order)
			return

	print("No matching order for current recipe.")


func _on_clear_recipe_pressed():
	current_recipe.clear()
	print("Recipe cleared. You can start a new coffee.")

func update_customer_satisfaction(coffee_order, delta):
	# Decrease satisfaction over time and handle unsatisfied customers
	var satisfaction_decrease_rate = 1  # Modify this value as needed
	var order_name = coffee_order["name"]  # Accessing the name of the customer
	if order_name in customer_satisfaction:
		customer_satisfaction[order_name] -= delta * satisfaction_decrease_rate
		if customer_satisfaction[order_name] <= 0:
			handle_unsatisfied_customer(coffee_order)


func handle_unsatisfied_customer(coffee_order):
	# Handle the scenario when a customer becomes unsatisfied
	print("Customer unsatisfied with order:", coffee_order["name"])
	# Implement effects like losing currency or points here
	customer_satisfaction.erase(coffee_order["name"])


func prepare_coffee(coffee_type):
	# Prepare the specified coffee type
	if coffee_type in coffee_types:
		print("Preparing", coffee_type, " - Level", current_level)
		current_recipe = []
		var timer_value = coffee_types[coffee_type].size() * (level_time_multiplier ** (current_level - 1)) * 200  # Increased timer
		var customer_name = customer_names[randi_range(0, customer_names.size() - 1)]  # Select a random name
		var coffee_order = {
			"name": customer_name,
			"type": coffee_type,
			"recipe": coffee_types[coffee_type],
			"time": timer_value,
			"timer": timer_value
		}
		orders_queue.append(coffee_order)
		customer_satisfaction[customer_name] = 100  # Set initial satisfaction value using the customer's name
	else:
		print("Unknown coffee type:", coffee_type)



func prepare_next_coffee():
	# Remove existing orders and reset customer satisfaction
	orders_queue.clear()
	customer_satisfaction.clear()

	# Prepare the next set of coffee orders for the current level
	for i in range(orders_per_level * 2):  # Larger number of orders
		var coffee_order = get_random_complex_coffee_order()
		prepare_coffee(coffee_order)

	current_level += 1
	update_GUI()

func get_random_complex_coffee_order():
	# Select random coffee types with increasing complexity as levels progress
	var coffee_order_list = get_ordered_complex_coffee_list(current_level)
	return coffee_order_list[randi_range(0, len(coffee_order_list) - 1)]

func get_ordered_complex_coffee_list(level):
	# List of all coffee types
	var all_coffee_types = [
		"Espresso", "Double Espresso", "Red Eye", "Black Eye", "Americano",
		"Long Black", "Macchiato", "Long Macchiato", "Cortado", "Breve",
		"Cappuccino", "Flat White", "Cafe Latte", "Mocha", "Vienna",
		"Affogato", "Cafe au Lait", "Brewed Coffee", "Iced Coffee"
		# Add more coffee types as needed
	]

	# Calculate the index to start from based on the level
	var start_index = (level - 1) % all_coffee_types.size()

	# Generate a list starting from the calculated index with an increment based on the level
	var ordered_list = []
	var orders_to_add = 1 + (level - 1) / 3
	for i in range(orders_to_add):
		ordered_list.append(all_coffee_types[(start_index + i) % all_coffee_types.size()])

	return ordered_list

func add_ingredient(ingredient):
	current_recipe.append(ingredient)
	print("Added", ingredient, "to the recipe:", current_recipe)
	# Check if the current recipe matches any order
	check_order_match()

func check_order_match():
	for coffee_order in orders_queue:
		if coffee_order["recipe"] == current_recipe:
			serve_order(coffee_order)
			break

func serve_order(coffee_order):
	if coffee_order["recipe"] == current_recipe:
		print("Order served successfully:", coffee_order["type"])
		currency += 10  # Adjust rewards as needed
		current_recipe.clear()
		orders_queue.erase(coffee_order)
		update_orders_display()
		
		# Check if all orders are completed
		if orders_queue.size() == 0:  # Corrected line
			progress_to_next_level()
	else:
		print("Incorrect order, try again")
		# Implement penalties for incorrect orders here

func progress_to_next_level():
	print("All orders completed. Progressing to next level!")
	current_level += 1
	prepare_next_coffee()  # Prepare coffee orders for the new level
	initialize_GUI_elements()  # Update the GUI for the new level, including ingredient buttons
	update_GUI()


func update_orders_display():
	var orders_text = "Orders:\n"
	
	for coffee_order in orders_queue:
		var order_name = coffee_order["name"]  # Accessing the name of the customer
		
		# Check if satisfaction level is greater than zero
		if order_name in customer_satisfaction and customer_satisfaction[order_name] > 0:
			orders_text += "- " + coffee_order["type"] + "\n"
			# Include ingredients in the order display
			orders_text += "  Ingredients: " + str(coffee_order["recipe"]) + "\n"
			# Display the customer satisfaction level
			orders_text += "  Satisfaction: " + str(int(customer_satisfaction[order_name])) + "\n"

	orders_label.text = orders_text


func update_GUI():
	# Update currency display
	update_currency_display()

	# Update level display
	update_level_display()

	# Update ingredient buttons (e.g., disabling them if an ingredient is used up)
	for ingredient in ingredient_buttons.keys():
		var button = ingredient_buttons[ingredient]
		button.disabled = !is_ingredient_available(ingredient)

	# Update orders display
	update_orders_display()

	# Any other UI updates can be placed here


func update_currency_display():
	# Assuming you have a label for currency
	var currency_label = find_child("CurrencyLabel")
	if currency_label:
		currency_label.text = "Currency: %d" % currency

func update_level_display():
	# Assuming you have a label for the current level
	var level_label = find_child("LevelLabel")
	if level_label:
		level_label.text = "Level: %d" % current_level

func is_ingredient_available(ingredient: String) -> bool:
	# Here you should implement the logic to check if an ingredient is available
	# For now, let's assume all ingredients are always available
	return true

func _on_timer_timeout():
	print("life lost");

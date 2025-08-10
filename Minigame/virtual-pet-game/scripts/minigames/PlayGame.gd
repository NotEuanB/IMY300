extends Node

var happiness: int = 50
var energy: int = 50
var play_time: int = 0

func _ready():
    # Initialize the mini-game
    pass

func play_with_pet():
    # Logic for playing with the pet
    happiness += 10
    energy -= 5
    play_time += 1
    update_pet_status()

func update_pet_status():
    # Update the pet's status based on playtime and needs
    if happiness > 100:
        happiness = 100
    if energy < 0:
        energy = 0

func end_game():
    # Logic to end the mini-game and return to the main game
    pass
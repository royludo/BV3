extends Node

var otherPlayerId = -1
var is_online_multi = false

var player_count = 2
enum Teams { TEAM_LEFT, TEAM_RIGHT }
var team_colors = { # not used
	Teams.TEAM_LEFT: Color(0.1, 0.5, 1.0, 1.0), # blue
	Teams.TEAM_RIGHT: Color(1.0, 0.2, 0.2, 1.0), # red
}
var player_colors = [
	Color(0.1, 0.5, 1.0, 1.0), # blue
	Color(1.0, 0.2, 0.2, 1.0), # red
	Color(0.2, 1.0, 0.2, 1.0), # green
	Color(1.0, 1.0, 0.2, 1.0),  # yellow
]
var players = []

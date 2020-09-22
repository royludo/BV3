extends Node

var otherPlayerId = -1
var is_online_multi = false

var player_count = 2
enum Team {TEAM_LEFT, TEAM_RIGHT}
var TeamColor = {
	Team.TEAM_LEFT: Color(0.1, 0.5, 1.0, 1.0), # blue
	Team.TEAM_RIGHT: Color(1.0, 0.2, 0.2, 1.0) # red
}
var Players = []

/// Alarm_0 — oPlayerHitbox
/// Fires 5 seconds after match winner is declared.
/// Returns all players to the menu.

global.match_phase = "countdown";  // reset for next time
room_goto(rm_menu);

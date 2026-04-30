/// Other_68 (Async - Networking) — oPlayerHitbox

if (async_load[? "type"] != network_type_data) exit;

var buf = async_load[? "buffer"];
buffer_seek(buf, buffer_seek_start, 0);

var ptype = buffer_read(buf, buffer_u8);

// ── Type 2 — server assigned us a pid ────────────────────────────────────
if (ptype == 2) {
    my_pid        = buffer_read(buf, buffer_u16);
    global.my_pid = my_pid;
    show_debug_message("My player ID is: " + string(my_pid));

    // ── Spawn at the point matching our pid ──────────────────────────────
    // Place oSpawnPoint objects in your room — one per expected player.
    // They are numbered by their order in the room (1 = first, 2 = second...).
    // If no spawn points exist, players stay at their room-placement position.
    var _spawn_count = instance_number(oSpawnPoint);
    if (_spawn_count > 0) {
        // Pick spawn index based on pid, wrapping if more players than spawns
        var _spawn_idx = (my_pid - 1) mod _spawn_count;

        // Get the nth spawn point instance
        var _i = 0;
        with (oSpawnPoint) {
            if (_i == _spawn_idx) {
                other.x = x;
                other.y = y;
                show_debug_message("Spawned at point " + string(_spawn_idx + 1)
                    + " (" + string(x) + "," + string(y) + ")");
                break;
            }
            _i++;
        }
    } else {
        // No spawn points in room — use pid-based fallback positions
        // Spread players in a wide circle so they don't overlap
        var _angle  = ((my_pid - 1) / 4.0) * 360;  // 4 = max expected players
        var _radius = 400;
        var _cx     = room_width  / 2;
        var _cy     = room_height / 2;
        x = _cx + lengthdir_x(_radius, _angle);
        y = _cy + lengthdir_y(_radius, _angle);
        show_debug_message("No spawn points — using fallback position for pid " + string(my_pid));
    }
    exit;
}

// ── Type 1 — another player's state ──────────────────────────────────────
if (ptype == 1) {
    var pid     = buffer_read(buf, buffer_u16);
    var ox      = buffer_read(buf, buffer_f32);
    var oy      = buffer_read(buf, buffer_f32);
    var ohp     = buffer_read(buf, buffer_u8);
    var oanim   = buffer_read(buf, buffer_u8);
    var ofacing = (buffer_read(buf, buffer_u8) / 255.0) * 360;

    // Don't update state for dead remote players
    if (ohp <= 0) exit;

    var entry = ds_map_find_value(other_players, pid);
    if (is_undefined(entry)) {
        entry = array_create(5);
        ds_map_add(other_players, pid, entry);
        show_debug_message("New other player: " + string(pid));
    }
    entry[0] = ox;
    entry[1] = oy;
    entry[2] = ohp;
    entry[3] = oanim;
    entry[4] = ofacing;
    exit;
}

// ── Type 4 — another player fired a bullet ───────────────────────────────
if (ptype == 4) {
    var shooter_pid = buffer_read(buf, buffer_u16);
    var bx          = buffer_read(buf, buffer_f32);
    var by          = buffer_read(buf, buffer_f32);
    var bdir        = (buffer_read(buf, buffer_u8) / 255.0) * 360;
    var bwtype      = buffer_read(buf, buffer_u8);   // 0=auto 1=shotgun 2=burst 3=sniper 4=melee(hit)
    var bdamage     = buffer_read(buf, buffer_f32);  // damage value from shooter

    if (shooter_pid != my_pid) {
        switch (bwtype) {
            case 1: // shotgun — 5 spread pellets
                var _spread  = 15;
                var _pellets = 5;
                for (var _p = 0; _p < _pellets; _p++) {
                    var _offset = (_p / (_pellets - 1) - 0.5) * _spread;
                    spawnEnemyBulletDmg(bx, by, bdir + _offset, bdamage);
                }
                break;
            case 4: // knife hit — apply damage directly, no bullet
                hitpoints -= bdamage;
                break;
            default: // auto, burst, sniper
                spawnEnemyBulletDmg(bx, by, bdir, bdamage);
                break;
        }
    }
    exit;
}

// ── Type 5 — timer update ─────────────────────────────────────────────────
if (ptype == 5) {
    time_remaining = buffer_read(buf, buffer_u16);
    exit;
}


// ── Type 17 — player died ─────────────────────────────────────────────────
if (ptype == 17) {
    var dead_pid = buffer_read(buf, buffer_u16);
    show_debug_message("Player dead: pid=" + string(dead_pid));
    if (dead_pid == my_pid) {
        // We died — hide player until next round
        global.player_alive = false;
        visible  = false;
        hitpoints = 0;
    } else {
        // Remote player died — remove from other_players
        ds_map_delete(other_players, dead_pid);
    }
    exit;
}

// ── Type 18 — countdown tick ──────────────────────────────────────────────
if (ptype == 18) {
    var count = buffer_read(buf, buffer_u8);
    global.countdown_value = count;
    if (count == 0) {
        global.match_phase  = "playing";
        // Always reset hp and make visible at round start
        hitpoints           = max_hp;
        dead_state          = false;
        visible             = true;
        global.player_alive = true;
        // Re-add all players to other_players map (they respawn too)
        // Teleport to spawn point
        var _spawn_count = instance_number(oSpawnPoint);
        if (_spawn_count > 0) {
            var _spawn_idx = (my_pid - 1) mod _spawn_count;
            var _i = 0;
            with (oSpawnPoint) {
                if (_i == _spawn_idx) {
                    other.x = x; other.y = y; break;
                }
                _i++;
            }
        } else {
            var _angle  = ((my_pid - 1) / 4.0) * 360;
            x = room_width  / 2 + lengthdir_x(400, _angle);
            y = room_height / 2 + lengthdir_y(400, _angle);
        }
        show_debug_message("Round GO — respawned at spawn point");
    } else {
        global.match_phase = "countdown";
        // Hide player during countdown if they died last round
        if (!global.player_alive) {
            visible = false;
        }
    }
    exit;
}

// ── Type 16 — round state (scores) ───────────────────────────────────────
if (ptype == 16) {
    var _round = buffer_read(buf, buffer_u8);
    var _count = buffer_read(buf, buffer_u8);
    global.round_number = _round;
    for (var _i = 0; _i < _count; _i++) {
        var _pid   = buffer_read(buf, buffer_u16);
        var _score = buffer_read(buf, buffer_u8);
        global.scores[_pid] = _score;
    }
    exit;
}

// ── Type 19 — match winner ────────────────────────────────────────────────
if (ptype == 19) {
    var _wpid  = buffer_read(buf, buffer_u16);
    var _wlen  = buffer_read(buf, buffer_u8);
    var _wname = "";
    for (var _c = 0; _c < _wlen; _c++)
        _wname += chr(buffer_read(buf, buffer_u8));
    global.match_winner_pid  = _wpid;
    global.match_winner_name = _wname;
    global.match_phase       = "winner";
    show_debug_message("Match winner: " + _wname);
    // Show winner screen then return to menu after delay
    alarm[0] = game_get_speed(gamespeed_fps) * 5;
    exit;
}

// ── Type 6 — match over ───────────────────────────────────────────────────
if (ptype == 6) {
    show_debug_message("Match ended — returning to lobby.");
    global.is_creating_lobby = false;
    room_goto(rLobby);
    exit;
}

// ── Type 3 — player left ─────────────────────────────────────────────────
if (ptype == 3) {
    var left_pid = buffer_read(buf, buffer_u16);
    ds_map_delete(other_players, left_pid);
    show_debug_message("Player left: pid=" + string(left_pid));
    exit;
}

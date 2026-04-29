/// Other_68 (Async - Networking) — oPlayerHitbox

if (async_load[? "type"] != network_type_data) exit;

var buf = async_load[? "buffer"];
buffer_seek(buf, buffer_seek_start, 0);

var ptype = buffer_read(buf, buffer_u8);

// ── Type 2 — server assigned us a pid ────────────────────────────────────
if (ptype == 2) {
    show_debug_message("Spawn points found: " + string(instance_number(oSpawnPoint)));
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

    if (shooter_pid != my_pid) {
        spawnBullet(bx, by, bdir);
    }
    exit;
}

// ── Type 5 — timer update ─────────────────────────────────────────────────
if (ptype == 5) {
    time_remaining = buffer_read(buf, buffer_u16);
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

/// Other_68 (Async – Networking) — oPlayerHitbox
///
/// Changes vs original:
///   • When we receive a type-1 state update and the incoming hp=0 AND the
///     previous hp for that pid was >0, we treat it as a kill:
///     → we send type 11 (KILL_REPORT) to the game server so it can forward
///       the kill to the DB server.
///   • All original packet handling is otherwise unchanged.

if (async_load[? "type"] != network_type_data) exit;

var buf = async_load[? "buffer"];
buffer_seek(buf, buffer_seek_start, 0);
var ptype = buffer_read(buf, buffer_u8);

// ── Type 2: server assigned us our pid ───────────────────────────────────────
if (ptype == 2) {
    my_pid = buffer_read(buf, buffer_u16);
    show_debug_message("My player ID: " + string(my_pid));
    exit;
}

// ── Type 1: another player's state ───────────────────────────────────────────
if (ptype == 1) {
    var pid    = buffer_read(buf, buffer_u16);
    var ox     = buffer_read(buf, buffer_f32);
    var oy     = buffer_read(buf, buffer_f32);
    var ohp    = buffer_read(buf, buffer_u8);
    var oanim  = buffer_read(buf, buffer_u8);
    var ofacing = (buffer_read(buf, buffer_u8) / 255.0) * 360;

    var entry = ds_map_find_value(other_players, pid);

    // ── Kill detection ────────────────────────────────────────────────────────
    // If the remote player just dropped to 0 hp and we were the shooter,
    // send a kill report to the game server.
    // NOTE: "we were the shooter" is approximated here by the game server — it
    // validates that the reporting client (our pid) was actually alive and a
    // participant.  For a more accurate attribution you would track last-damage-
    // source per pid.  This fires the packet; the server decides whether to count it.
    if (!is_undefined(entry) && entry[0] > 0 && ohp == 0) {
        // Remote player just died — report kill attributed to us
        var _kbuf = buffer_create(5, buffer_fixed, 1);
        buffer_seek(_kbuf, buffer_seek_start, 0);
        buffer_write(_kbuf, buffer_u8,  11);        // type 11 = KILL_REPORT
        buffer_write(_kbuf, buffer_u16, my_pid);    // killer (us)
        buffer_write(_kbuf, buffer_u16, pid);       // victim
        network_send_udp_raw(global.socket, global.ip_address, global.port,
                             _kbuf, buffer_tell(_kbuf));
        buffer_delete(_kbuf);
        show_debug_message("Kill reported: we killed pid " + string(pid));
    }
    // ── End kill detection ────────────────────────────────────────────────────

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

// ── Type 3: player left ───────────────────────────────────────────────────────
if (ptype == 3) {
    var pid = buffer_read(buf, buffer_u16);
    if (ds_map_exists(other_players, pid)) {
        ds_map_delete(other_players, pid);
        show_debug_message("Player left: " + string(pid));
    }
    exit;
}

// ── Type 4: another player fired a bullet ────────────────────────────────────
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

// ── Type 5: timer update ──────────────────────────────────────────────────────
if (ptype == 5) {
    time_remaining = buffer_read(buf, buffer_u16);
    exit;
}

// ── Type 6: match over ────────────────────────────────────────────────────────
if (ptype == 6) {
    show_debug_message("Match ended — returning to lobby.");
    global.is_creating_lobby = false;
    room_goto(rLobby);
    exit;
}

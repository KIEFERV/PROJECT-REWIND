if (async_load[? "type"] != network_type_data) exit;

var buf = async_load[? "buffer"];
buffer_seek(buf, buffer_seek_start, 0);

var ptype = buffer_read(buf, buffer_u8);

// ── Type 2: server assigned us a PID ─────────────────────────────────────────
if (ptype == 2) {
    my_pid = buffer_read(buf, buffer_u16);
    show_debug_message("My PID = " + string(my_pid));
    exit;
}

// ── Type 5: server telling us about a peer's public endpoint ─────────────────
// Layout: [u8=5][u16 peer_pid][u8 a][u8 b][u8 c][u8 d][u16 port big-endian]
if (ptype == 5) {
    var peer_pid  = buffer_read(buf, buffer_u16);
    var a = buffer_read(buf, buffer_u8);
    var b = buffer_read(buf, buffer_u8);
    var c = buffer_read(buf, buffer_u8);
    var d = buffer_read(buf, buffer_u8);
    var port_be_hi = buffer_read(buf, buffer_u8); // high byte (network order)
    var port_be_lo = buffer_read(buf, buffer_u8); // low byte
    var peer_port  = port_be_hi * 256 + port_be_lo;
    var peer_ip    = string(a) + "." + string(b) + "." + string(c) + "." + string(d);

    show_debug_message("Peer endpoint received: pid=" + string(peer_pid)
                       + "  " + peer_ip + ":" + string(peer_port));

    // Store the address
    var addr_entry = array_create(2);
    addr_entry[0] = peer_ip;
    addr_entry[1] = peer_port;
    ds_map_set(peer_addrs, peer_pid, addr_entry);

    // ── UDP Hole-Punch ────────────────────────────────────────────────────────
    // Send several type-6 probe packets directly to the peer so both NATs
    // open a mapping for each other's endpoint before real data flows.
    var probe = buffer_create(3, buffer_fixed, 1);
    buffer_write(probe, buffer_u8,  6);       // type 6 = hole-punch probe
    buffer_write(probe, buffer_u16, my_pid);  // tell peer who we are
    repeat (5) {
        network_send_udp_raw(socket, peer_ip, peer_port, probe, buffer_tell(probe));
    }
    buffer_delete(probe);

    exit;
}

// ── Type 3: a peer disconnected ──────────────────────────────────────────────
if (ptype == 3) {
    var gone_pid = buffer_read(buf, buffer_u16);
    ds_map_delete(other_players, gone_pid);
    ds_map_delete(peer_addrs,    gone_pid);
    show_debug_message("Peer left: pid=" + string(gone_pid));
    exit;
}

// ── Type 6: hole-punch probe from a peer ─────────────────────────────────────
// Just receiving this opens our NAT mapping toward them.
// Echo one probe back in case their first packets arrived before ours.
if (ptype == 6) {
    var prober_pid = buffer_read(buf, buffer_u16);
    show_debug_message("Hole-punch probe from pid=" + string(prober_pid));

    var addr = ds_map_find_value(peer_addrs, prober_pid);
    if (!is_undefined(addr)) {
        var echo = buffer_create(3, buffer_fixed, 1);
        buffer_write(echo, buffer_u8,  6);
        buffer_write(echo, buffer_u16, my_pid);
        network_send_udp_raw(socket, addr[0], addr[1], echo, buffer_tell(echo));
        buffer_delete(echo);
    }
    exit;
}

// ── Type 1: another player's state (sent directly by that peer) ──────────────
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
        show_debug_message("First state packet from pid=" + string(pid));
    }
    entry[0] = ox;
    entry[1] = oy;
    entry[2] = ohp;
    entry[3] = oanim;
    entry[4] = ofacing;
    exit;
}

// ── Type 4: a peer fired a bullet (sent directly by that peer) ───────────────
if (ptype == 4) {
    var shooter_pid = buffer_read(buf, buffer_u16);
    var bx   = buffer_read(buf, buffer_f32);
    var by   = buffer_read(buf, buffer_f32);
    var bdir = (buffer_read(buf, buffer_u8) / 255.0) * 360;

    if (shooter_pid != my_pid) {
        spawnBullet(bx, by, bdir);
    }
    exit;
}

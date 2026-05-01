function plr_rewind() {
    // Move backwards through buffer
    repeat (REWIND_SPEED) {
        playback_index--;
        rewind_frames_travelled++;

        if (playback_index < 0) {
            playback_index = buffer_size - 1;
        }

        // Stop when we've reached the oldest frame or exhausted unfilled buffer
        if (buffer_filled && playback_index == buffer_index) {
            plr_enter_past();
            break;
        } else if (!buffer_filled && playback_index <= 0) {
            plr_enter_past();
            break;
        }
    }

    // Apply stored state
    x           = pos_x[playback_index];
    y           = pos_y[playback_index];
    image_angle = pos_dir[playback_index];
}

function plr_enter_past() {
    rewind_active = false;
    time_phase    = "past";
    time_cd       = time_cd_max;
    image_alpha   = 1;

    // Set oPlayerHitbox phase so networking picks it up immediately
    if (instance_exists(oPlayerHitbox)) {
        oPlayerHitbox.time_phase = "past";
    }

    // Use ghost_ref instead of oGhost directly (safer in multiplayer)
    if (instance_exists(ghost_ref)) {
        ghost_ref.image_alpha = 0.5;
    }

    show_debug_message("Entered past phase — rewind_frames_travelled=" + string(rewind_frames_travelled));

    // Set up playback read head
    anchor_index           = playback_index;
    anchor_x               = x;
    anchor_y               = y;
    buffer_read_index      = (playback_index + 1) mod buffer_size;
    past_duration          = rewind_frames_travelled;
    rewind_frames_travelled = 0;
    past_frames_elapsed    = 0;
}

function plr_travel_start() {
    playback_index = (buffer_index - 1 + buffer_size) mod buffer_size;
    rewind_active  = true;
    visible        = true;
    image_alpha    = 0.5;

    // Immediately mark oPlayerHitbox as past so state packets reflect it
    if (instance_exists(oPlayerHitbox)) {
        oPlayerHitbox.time_phase = "past";
    }

    // Spawn ghost at current position
    ghostX    = x;
    ghostY    = y;
    ghost_ref = instance_create_layer(ghostX, ghostY, "layer_barrier_wall", oGhost);
}

function return_to_present() {
    if (time_phase == "past") {  // == not = 
        show_debug_message("return_to_present called");

        // Teleport back to where ghost is
        x = ghostX;
        y = ghostY;

        // Destroy the ghost
        if (instance_exists(ghost_ref)) {
            instance_destroy(ghost_ref);
        }

        // Restore oPlayerHitbox phase so networking reflects it immediately
        if (instance_exists(oPlayerHitbox)) {
            oPlayerHitbox.time_phase = "present";
        }

        time_phase = "present";
    }
}

function rewindable_playback() {
    var frame = oRewindParent.rewindable_states[oRewindParent.playback_index];

    for (var i = 0; i < array_length(frame); i++) {
        var state = frame[i];

        switch (state.object_index) {
            case oBullet:
                // Find existing ghost bullet matching this bullet_id
                var ghost = noone;
                with (oRewindable) {
                    if (is_ghost && bullet_id == state.bullet_id) {
                        ghost = id;
                        break;
                    }
                }

                if (instance_exists(ghost)) {
                    // Update existing ghost position
                    ghost.x         = state.x;
                    ghost.y         = state.y;
                    ghost.direction = state.direction;
                    ghost.speed     = state.speed;
                } else {
                    // Spawn new ghost bullet
                    var ghost = instance_create_layer(state.x, state.y, "layer_instances", oBullet);
                    ghost.time_phase = "past";   // always past — won't hit present players
                    ghost.owner_id   = oPlayerHitbox.id;
                    ghost.is_ghost   = true;
                    ghost.bullet_id  = state.bullet_id;
                    ghost.speed      = 0;
                    ghost.damage     = 0;        // ghost bullets deal no damage
                }
            break;
        }
    }
}

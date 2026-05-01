function bullet_rewind_buffer(idx) {
    var state = {
        object_index: object_index,
        x:            x,
        y:            y,
        direction:    direction,
        speed:        speed,
        bullet_id:    bullet_id
    };

    array_push(oRewindParent.rewindable_states[idx], state);
}

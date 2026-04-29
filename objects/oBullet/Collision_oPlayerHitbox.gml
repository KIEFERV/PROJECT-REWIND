if (oPlayerHitbox.dead_state = false && owner_id != oPlayerHitbox.id) {
    oPlayerHitbox.hitpoints -= damage;
    instance_destroy(self);
}

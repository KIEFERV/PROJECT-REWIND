/// oBullet — Collision with oPlayerHitbox

// Skip if this bullet belongs to the player being hit
if (other.id == owner_id) exit;

// Skip if player is already dead
if (other.dead_state) exit;

other.hitpoints -= damage;
instance_destroy();



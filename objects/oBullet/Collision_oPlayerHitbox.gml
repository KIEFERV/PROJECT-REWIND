/// oBullet — Collision with oPlayerHitbox

// Skip if the player who owns this bullet is the one being hit
if (other.id == owner_id) exit;

// Skip if player is already dead
if (other.dead_state) exit;

other.hitpoints -= 10;
instance_destroy();

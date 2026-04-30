/// oBullet — Collision with oPlayerHitbox

<<<<<<< HEAD
// Skip if the player who owns this bullet is the one being hit
=======
// Skip if this bullet belongs to the player being hit
>>>>>>> parent of 7349df5 (Merge pull request #53 from KIEFERV/round-logic)
if (other.id == owner_id) exit;

// Skip if player is already dead
if (other.dead_state) exit;

<<<<<<< HEAD
other.hitpoints -= 10;
=======
other.hitpoints -= damage;
>>>>>>> parent of 7349df5 (Merge pull request #53 from KIEFERV/round-logic)
instance_destroy();

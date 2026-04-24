if (oPlayerHitbox.dead_state = false && owner_id != oPlayerHitbox.id){
	oPlayerHitbox.hitpoints -= 10;
	//instance_destroy(self);
}

//wall damage handling,
//this is easy because you can just override this function 
//in other walls if there are other specific situations


broken = false;
HitByLast = -1; //for keeping track of damage type cases

function take_damage(_amount, damage_type){ 
	if(!is_breakable) return;
	if(broken) return;
	
	HitByLast = damage_type;
	wall_hp -= _amount;
	
	if (wall_hp <= 0 && broken = false){
	break_wall();
	}
}


function break_wall(){

broken = true;
self.on_break();
instance_destroy();

}

function on_break(){
	//nothing on default, child overrides
	show_debug_message("WRONG on_break() triggered! hp = " + string(wall_hp) + ", broken = " + string(broken));
}
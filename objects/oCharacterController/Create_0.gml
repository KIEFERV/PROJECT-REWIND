event_inherited();



// Movement Vectors & Values
move_x         = 0;
move_y         = 0;
move_dir       = 0;
move_speed     = 0;
move_norm_x    = 0;
move_norm_y    = 0;
move_speed_mod = 1;
move_friction  = 1;

// Impulse Vector
impulse_force_x  = 0;
impulse_force_y  = 0;
impulse_friction = 0.85;
impulse_mod      = 1;

// Constant Vector
constant_force_x = 0;
constant_force_y = 0;

// Total Speed
velocity_x = 0;
velocity_y = 0;
velocity = 0;


function add_impulse_position(_x, _y, _power){
	var _vx = x - _x,
	    _vy = y - _y,
		_dist = _vx * _vx + _vy * _vy;
		
	if (_dist != 0){
		// Normalize, apply magnitude, and add to current impusle vector
		_dist = sqrt(_dist);
		_vx = impulse_force_x + _vx / _dist * _power; // Cosine * magnitude
		_vy = impulse_force_y + _vy / _dist * _power; // Sine * magnitude
		
		// Limit to maximum impulse force
		_dist = sqrt(_vx * _vx + _vy * _vy);
		
		if (_dist > C_MAXIMUM_IMPULSE_FORCE){ //DOUBLE CHECK THIS
			// Normalize and apply magnitude
			impulse_force_x = _vx / _dist * C_MAXIMUM_IMPULSE_FORCE; // Cosine * magnitude
			impulse_force_y = _vy / _dist * C_MAXIMUM_IMPULSE_FORCE; // Sine * magnitude
		}else{
			impulse_force_x = _vx;
			impulse_force_y = _vy;
		}
	}
}

function add_constant_force(_direction, _power){
	constant_force_x += dcos(_direction) * _power;
	constant_force_y -= dsin(_direction) * _power;
}
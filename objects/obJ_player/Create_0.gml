fire_rate_mult   = 1;
fire_rate_timer  = 0;

move_speed_mult  = 1;
move_speed_timer = 0;

ricochet_timer   = 0;
cover_timer      = 0;

base_move_speed  = 5;
base_fire_delay  = 12;

global.POWER_FIRE_RATE = "fire_rate";
global.POWER_MOVE_SPEED = "move_speed";
global.POWER_RICOCHET = "ricochet";
global.POWER_COVER = "cover";

scr_powerup_init(self);

shoot_timer = 0;
cover_cooldown = 0;
if (!variable_global_exists("primary_weapon")) global.primary_weapon = "pistol";
if (!variable_global_exists("secondary_weapon")) global.secondary_weapon = "shotgun";

primary_list = ["pistol", "rifle", "smg"];
secondary_list = ["shotgun", "sniper", "launcher"];

primary_index = 0;
secondary_index = 0;

for (var i = 0; i < array_length(primary_list); i++) {
    if (primary_list[i] == global.primary_weapon) primary_index = i;
}

for (var i = 0; i < array_length(secondary_list); i++) {
    if (secondary_list[i] == global.secondary_weapon) secondary_index = i;
}

active_column = 0; // 0 = primary, 1 = secondary
status_text = "Choose your loadout.";
hover_play = false;
hover_back = false;
button_w = 160;
button_h = 42;
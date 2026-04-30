if (!variable_global_exists("primary_weapon"))   global.primary_weapon   = "assault_rifle";
if (!variable_global_exists("secondary_weapon")) global.secondary_weapon = "pistol";

primary_list   = ["assault_rifle", "shotgun", "smg", "sniper"];
secondary_list = ["pistol", "knife"];

primary_info = [
    "Auto | 30 mag  •  120 reserve",
    "Shotgun | 5 mag  •  20 reserve | 5 pellets @ 0.5 dmg",
    "3-shot Burst | 24 mag  •  96 reserve",
    "Sniper | 3 mag  •  15 reserve | One-shot kill"
];
secondary_info = [
    "Semi-auto | 12 mag  •  60 reserve",
    "Melee | 1 dmg per hit | No ammo"
];

primary_index   = 0;
secondary_index = 0;

for (var i = 0; i < array_length(primary_list); i++) {
    if (primary_list[i] == global.primary_weapon) primary_index = i;
}
for (var i = 0; i < array_length(secondary_list); i++) {
    if (secondary_list[i] == global.secondary_weapon) secondary_index = i;
}

active_column = 0;
status_text   = "Choose your loadout.";
hover_play    = false;
hover_back    = false;
button_w      = 160;
button_h      = 42;

status_text = "Choose your loadout.";
hover_play = false;
hover_back = false;
button_w = 160;
button_h = 42;
// Multiplayer lock-in state
locked_in = false;

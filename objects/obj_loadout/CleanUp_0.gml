/// CleanUp_0 — obj_loadout

if (ds_exists(weapon_labels, ds_type_map)) ds_map_destroy(weapon_labels);
if (ds_exists(weapon_descs,  ds_type_map)) ds_map_destroy(weapon_descs);

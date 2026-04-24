if (variable_instance_exists(id, "powerups")) {
    if (ds_exists(powerups, ds_type_map)) {
        ds_map_destroy(powerups);
    }
}

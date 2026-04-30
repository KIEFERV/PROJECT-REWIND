/// CleanUp_0 — oEscController

if (ds_exists(esc_history, ds_type_stack))
    ds_stack_destroy(esc_history);

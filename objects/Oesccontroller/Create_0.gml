/// Create_0 — oEscController
/// Persistent object that handles global ESC key navigation.
/// Place one instance in your first/menu room only — it persists across rooms.

persistent = true;

// Room history stack — stores previous room names
esc_history = ds_stack_create();

// Rooms where ESC is blocked entirely
esc_blocked_rooms = [
    rMovementTesting,   // in-match — use in-game menu instead
    rLobby              // in lobby — handled by oLobby itself
];

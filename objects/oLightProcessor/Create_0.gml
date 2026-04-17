/// @description init shadow casting

// Shadow culling radius — oLightBox objects further than this distance
// from the player are skipped during shadow projection.
// Increase if shadows disappear at the edges of large screens;
// decrease to improve performance in dense scenes.
global.shadow_view_radius = 1024;

vertex_format_begin();
vertex_format_add_position();
vertex_format_add_color();
VertexFormat = vertex_format_end();

VBuffer = vertex_create_buffer();

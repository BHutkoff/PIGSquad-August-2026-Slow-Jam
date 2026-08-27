shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

uniform vec4 fog_color : source_color = vec4(0.72, 0.79, 0.84, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.58;
uniform float noise_scale : hint_range(1.0, 16.0) = 6.0;
uniform float drift_speed : hint_range(0.0, 0.25) = 0.035;
uniform float emission_strength : hint_range(0.0, 3.0) = 1.15;

void fragment() {
	vec2 drifting_uv = UV * noise_scale + vec2(TIME * drift_speed, -TIME * drift_speed * 0.43);
	float broad_mist = sin(drifting_uv.x * 1.17 + sin(drifting_uv.y * 0.81));
	float fine_mist = sin(drifting_uv.y * 2.23 - drifting_uv.x * 0.67 + TIME * drift_speed);
	float mist = 0.72 + broad_mist * 0.12 + fine_mist * 0.07;
	float horizontal_edge = smoothstep(0.0, 0.16, UV.x) * smoothstep(0.0, 0.16, 1.0 - UV.x);
	float vertical_edge = smoothstep(0.0, 0.11, UV.y) * smoothstep(0.0, 0.11, 1.0 - UV.y);
	float center_glow = 1.0 - abs(UV.x * 2.0 - 1.0);
	float alpha = opacity * mist * horizontal_edge * vertical_edge;
	vec3 final_color = fog_color.rgb * (0.88 + center_glow * 0.18);
	ALBEDO = final_color;
	EMISSION = final_color * emission_strength;
	ALPHA = alpha;
}

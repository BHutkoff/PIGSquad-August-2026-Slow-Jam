shader_type spatial;
render_mode unshaded, depth_draw_opaque, cull_back;

const int MAX_ACTIVE_PULSES = 6;

uniform float reveal_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 edge_color : source_color = vec3(1.0);
uniform float edge_intensity : hint_range(0.0, 4.0) = 1.0;
uniform float edge_power : hint_range(0.25, 8.0) = 2.5;
uniform float surface_brightness : hint_range(0.0, 0.5) = 0.04;

uniform int active_pulse_count = 0;
uniform vec3 pulse_origins[MAX_ACTIVE_PULSES];
uniform vec3 pulse_forwards[MAX_ACTIVE_PULSES];
uniform float cone_minimum_dots[MAX_ACTIVE_PULSES];
uniform float pulse_max_distances[MAX_ACTIVE_PULSES];
uniform float pulse_radii[MAX_ACTIVE_PULSES];
uniform float wave_band_widths[MAX_ACTIVE_PULSES];
uniform float trail_hold_lengths[MAX_ACTIVE_PULSES];
uniform float trail_fade_lengths[MAX_ACTIVE_PULSES];
uniform float distance_brightnesses[MAX_ACTIVE_PULSES];

uniform float wavefront_intensity : hint_range(0.0, 4.0) = 1.0;
uniform float wavefront_surface_boost : hint_range(0.0, 2.0) = 0.0;
uniform float trail_intensity : hint_range(0.0, 2.0) = 0.5;
uniform float brightness_multiplier : hint_range(0.75, 1.25) = 1.0;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float view_facing = max(dot(normalize(NORMAL), normalize(VIEW)), 0.0);
	float rim = pow(1.0 - view_facing, edge_power);
	float surface_facing = mix(0.35, 1.0, view_facing);
	float surface_contribution = surface_brightness * surface_facing;
	float edge_contribution = rim * edge_intensity;
	float combined_reveal_intensity = 0.0;

	for (int pulse_index = 0; pulse_index < MAX_ACTIVE_PULSES; pulse_index++) {
		if (pulse_index >= active_pulse_count) {
			break;
		}
		vec3 origin_to_fragment = world_position - pulse_origins[pulse_index];
		float fragment_distance = length(origin_to_fragment);
		vec3 fragment_direction = normalize(origin_to_fragment);
		float cone_mask = step(
			cone_minimum_dots[pulse_index],
			dot(fragment_direction, normalize(pulse_forwards[pulse_index]))
		);
		float range_mask = 1.0 - step(
			pulse_max_distances[pulse_index], fragment_distance
		);
		float half_band = max(wave_band_widths[pulse_index] * 0.5, 0.001);
		float distance_from_front = fragment_distance - pulse_radii[pulse_index];
		float band = 1.0 - smoothstep(
			half_band * 0.15, half_band, abs(distance_from_front)
		);

		float distance_behind_front = pulse_radii[pulse_index] - fragment_distance;
		float reached = smoothstep(-half_band, half_band, distance_behind_front);
		float trail_age_distance = max(distance_behind_front - half_band, 0.0);
		float trail_fade = 1.0 - smoothstep(
			trail_hold_lengths[pulse_index],
			trail_hold_lengths[pulse_index]
				+ max(trail_fade_lengths[pulse_index], 0.001),
			trail_age_distance
		);
		float trail = reached * trail_fade * trail_intensity;
		float wave_visibility = max(band * wavefront_intensity, trail)
			* cone_mask * range_mask;
		float pulse_reveal_intensity = (
			(surface_contribution + edge_contribution) * wave_visibility
			+ wavefront_surface_boost * band * cone_mask * range_mask
		) * distance_brightnesses[pulse_index];
		combined_reveal_intensity = max(
			combined_reveal_intensity, pulse_reveal_intensity
		);
	}

	ALBEDO = edge_color * combined_reveal_intensity * reveal_amount * brightness_multiplier;
	ROUGHNESS = 1.0;
}

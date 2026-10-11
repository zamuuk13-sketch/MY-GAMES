shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 blur_direction = vec2(0.0);
uniform float blur_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 offset = blur_direction * clamp(blur_strength, 0.0, 0.72) * 0.9;
	vec4 color = texture(screen_texture, SCREEN_UV) * 0.28;
	color += texture(screen_texture, SCREEN_UV - offset * 1.00) * 0.22;
	color += texture(screen_texture, SCREEN_UV + offset * 1.00) * 0.22;
	color += texture(screen_texture, SCREEN_UV - offset * 2.00) * 0.14;
	color += texture(screen_texture, SCREEN_UV + offset * 2.00) * 0.14;
	COLOR = color;
}

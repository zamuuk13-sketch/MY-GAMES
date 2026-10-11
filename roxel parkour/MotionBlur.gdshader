shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform vec2 blur_vector = vec2(0.0, 0.0);
uniform float blur_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 offset = blur_vector * blur_amount;
	vec4 color = texture(screen_texture, SCREEN_UV) * 0.20;
	color += texture(screen_texture, SCREEN_UV + offset * -1.0) * 0.16;
	color += texture(screen_texture, SCREEN_UV + offset * -0.66) * 0.14;
	color += texture(screen_texture, SCREEN_UV + offset * -0.33) * 0.12;
	color += texture(screen_texture, SCREEN_UV + offset * 0.33) * 0.12;
	color += texture(screen_texture, SCREEN_UV + offset * 0.66) * 0.14;
	color += texture(screen_texture, SCREEN_UV + offset) * 0.12;
	COLOR = color;
}

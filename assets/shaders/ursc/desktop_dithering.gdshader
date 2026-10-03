// Adapted from URSC canvas_item/dithering.gdshader, Zorochase (MIT).
// https://github.com/Zorochase/ultimate-retro-shader-collection
// Uses a screen texture instead of TEXTURE, an inline 4x4 Bayer pattern,
// and a blend strength so small UI text retains its contrast.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float color_depth : hint_range(0, 32, 1) = 32;
uniform float strength : hint_range(0, 1) = 0.2;

float bayer(vec2 pixel) {
	int x = int(mod(pixel.x, 4.0));
	int y = int(mod(pixel.y, 4.0));
	const float pattern[16] = float[16](
		0.0, 8.0, 2.0, 10.0,
		12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0, 9.0,
		15.0, 7.0, 13.0, 5.0
	);
	return (pattern[y * 4 + x] + 0.5) / 16.0 - 0.5;
}

void fragment() {
	vec4 base = texture(screen_texture, SCREEN_UV);
	if (color_depth > 0.0) {
		vec3 reduced = round(base.rgb * color_depth + bayer(FRAGCOORD.xy)) / color_depth;
		base.rgb = mix(base.rgb, reduced, strength);
	}
	COLOR = base;
}

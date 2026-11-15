shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.35, 0.85, 1.0, 1.0);
uniform vec4 flame_color : source_color = vec4(1.0, 0.55, 0.15, 1.0);
uniform float glow_strength : hint_range(0.0, 4.0) = 2.4;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform float enabled : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (enabled < 0.5) {
		COLOR = col;
		return;
	}

	vec2 px = TEXTURE_PIXEL_SIZE * (2.0 + pulse * 1.5);
	float outline = 0.0;
	outline += texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	outline += texture(TEXTURE, UV + vec2(-px.x, 0.0)).a;
	outline += texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	outline += texture(TEXTURE, UV + vec2(0.0, -px.y)).a;
	outline += texture(TEXTURE, UV + vec2(px.x, px.y)).a;
	outline += texture(TEXTURE, UV + vec2(-px.x, px.y)).a;
	outline += texture(TEXTURE, UV + vec2(px.x, -px.y)).a;
	outline += texture(TEXTURE, UV + vec2(-px.x, -px.y)).a;
	outline = clamp(outline / 2.5, 0.0, 1.0);

	float edge = outline * (1.0 - col.a);
	float flicker = 0.65 + 0.35 * pulse;
	vec3 rim = mix(glow_color.rgb, flame_color.rgb, pulse * 0.55);
	vec3 glow = rim * edge * glow_strength * flicker;
	vec3 body = mix(col.rgb, glow_color.rgb, 0.18 * col.a);
	COLOR = vec4(body + glow, max(col.a, edge));
}

shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec4 overlay_color : source_color = vec4(1.0, 0.5, 0.0, 0.2); // 橙色滤镜

void fragment() {
    vec4 screen_color = texture(screen_texture, SCREEN_UV);
    // 简单的颜色混合
    COLOR = mix(screen_color, overlay_color, overlay_color.a);
}

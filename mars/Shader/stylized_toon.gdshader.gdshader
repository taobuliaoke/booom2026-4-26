shader_type spatial;

uniform vec3 albedo : source_color = vec3(1.0); // 基础颜色
uniform sampler2D albedo_texture : source_color;
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.5; // 阴影分界线
uniform float shadow_softness : hint_range(0.0, 1.0) = 0.02; // 阴影边缘软度

void fragment() {
    vec4 tex_color = texture(albedo_texture, UV);
    ALBEDO = albedo * tex_color.rgb;
}

void light() {
    // 计算光照强度（Toon Shading 核心）
    float dot_product = dot(NORMAL, LIGHT);
    float diffuse_amount = smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness, dot_product);
    
    // 应用光照颜色
    DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * ALBEDO * diffuse_amount;
}

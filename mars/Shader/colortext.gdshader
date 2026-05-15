shader_type canvas_item;

// 开启混合模式，这是解决白框的基础
render_mode blend_mix;

group_uniforms Effect_Settings;
uniform vec2 red_displacement = vec2(2.0, 0.0);   // 红色偏移像素
uniform vec2 blue_displacement = vec2(-2.0, 0.0); // 蓝色偏移像素
uniform vec4 red_tint : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 blue_tint : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform float shadow_opacity : hint_range(0.0, 1.0) = 0.8;

void fragment() {
	// 1. 获取屏幕像素步长，用于锁定缩放感
	vec2 ps = SCREEN_PIXEL_SIZE;
	
	// 2. 采样本体颜色
	// 在 CanvasGroup 中，TEXTURE 代表子节点渲染后的整张贴图
	vec4 main_tex = texture(TEXTURE, UV);
	
	// 3. 计算锁定缩放的 UV 偏移
	vec2 r_uv_off = red_displacement * ps;
	vec2 b_uv_off = blue_displacement * ps;
	
	// 4. 采样影子层的 Alpha
	float a_red = texture(TEXTURE, UV - r_uv_off).a;
	float a_blue = texture(TEXTURE, UV - b_uv_off).a;
	
	// --- 核心：解决白框的逻辑 ---
	// 如果本体和影子都没有像素，直接丢弃，不进行任何绘制
	if (main_tex.a + a_red + a_blue < 0.001) {
		discard;
	}
	
	// 5. 颜色合成
	vec3 r_layer = red_tint.rgb * a_red;
	vec3 b_layer = blue_tint.rgb * a_blue;
	
	// 混合影子层（蓝影在底，红影盖在上面）
	vec3 shadow_rgb = mix(b_layer, r_layer, a_red);
	float shadow_a = max(a_red, a_blue) * shadow_opacity;
	
	// 6. 最终合成：将白字盖在影子上
	vec3 final_rgb = mix(shadow_rgb, vec3(1.0), main_tex.a);
	float final_alpha = max(main_tex.a, shadow_a);
	
	// 7. 输出最终颜色
	// 乘以 COLOR 是为了保留来自 CanvasGroup 或 Label 的透明度动画（如下滑淡入）
	COLOR = vec4(final_rgb, final_alpha) * COLOR;
}
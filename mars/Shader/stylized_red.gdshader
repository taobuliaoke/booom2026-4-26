// film_grain_pure.gdshader
shader_type canvas_item;

// 可调参数
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0, 0.3) = 0.1;  // 颗粒强度（建议不超过0.3）
uniform float speed : hint_range(0, 5) = 2.0;       // 颗粒动态速度
uniform vec3 channel_bias = vec3(0.8, 0.6, 1.0);    // RGB通道颗粒强度权重

void fragment() {
	// 获取原屏幕颜色
	vec4 color = texture(SCREEN_TEXTURE,SCREEN_UV);
	
	// ---- 基础颗粒生成 ----
	// 使用坐标与时间生成伪随机噪声
	float noise = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453 + TIME * speed);
	noise = (noise - 0.5) * intensity; // 映射到 [-0.5, 0.5] 范围，再乘以强度
	
	// ---- 差异化RGB通道颗粒 ----
	color.r += noise * channel_bias.r; // 红色通道颗粒较弱
	color.g += noise * channel_bias.g; // 绿色通道颗粒中等
	color.b += noise * channel_bias.b; // 蓝色通道颗粒最强
	
	COLOR = color;
}
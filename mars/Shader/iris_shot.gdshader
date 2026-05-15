shader_type canvas_item;

// 1.5 为全开，0.0 为全黑
uniform float circle_size : hint_range(0.0, 1.5) = 1.5; 
// 这里的 center 使用 0.0 到 1.0 之间的数值
uniform vec2 center = vec2(0.5, 0.5); 
uniform float feather : hint_range(0.0, 0.5) = 0.05;

void fragment() {
    // 使用 UV 而不是 SCREEN_UV 可以解决“随鼠标滚轮移动”的问题
    // 因为 UV 是相对于节点自身的坐标，不会受编辑器视口缩放影响
    vec2 uv = UV;

    // 修复椭圆问题：获取当前物体的宽高比（1600/1200 = 1.333）
    // 在 Godot 4 中，可以通过输入 uniform 或者使用内置的屏幕比例
    float ratio = 1.3333; // 你的项目是 1600x1200 
    
    vec2 corrected_uv = vec2(uv.x * ratio, uv.y);
    vec2 corrected_center = vec2(center.x * ratio, center.y);

    // 计算到圆心的距离
    float dist = distance(corrected_uv, corrected_center);
    
    // 平滑遮罩计算
    float mask = smoothstep(circle_size, circle_size - feather, dist);
    
    // 设置颜色：圆圈内透明 (1.0 - mask)，圆圈外纯黑
    // 我们直接操作 ColorRect 的 Alpha 通道
    COLOR = vec4(vec3(0.0), 1.0 - mask);
}
shader_type canvas_item;

uniform float speed : hint_range(0.0, 10.0) = 3.0;
uniform float frequency : hint_range(0.0, 50.0) = 15.0;
uniform float amplitude : hint_range(0.0, 0.1) = 0.1;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.2; // 边缘波及范围

void vertex() {
    // 获取 UV（0.0 到 1.0）
    // 注意：CanvasItem 的 VERTEX 是局部坐标，UV 决定了我们在贴图的哪个位置
    vec2 uv = UV;

    // 计算到边缘的距离 (0 表示在边缘，0.5 表示在中心)
    float dist_to_edge_x = min(uv.x, 1.0 - uv.x);
    float dist_to_edge_y = min(uv.y, 1.0 - uv.y);
    float edge_mask = 1.0 - smoothstep(0.0, edge_softness, min(dist_to_edge_x, dist_to_edge_y));

    // 只对边缘应用正弦波偏移
    float wave = sin(TIME * speed + (uv.x + uv.y) * frequency) * amplitude * 100.0;
    
    VERTEX += wave * edge_mask;
}
shader_type canvas_item;

uniform float jitter_speed : hint_range(1.0, 20.0) = 10.0; // 抖动频率
uniform float jitter_amount : hint_range(0.0, 5.0) = 1.0; // 抖动幅度

// 简单的随机函数
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void vertex() {
    // 基于时间产生阶梯状的变化（模拟定格动画的帧率）
    float snapped_time = floor(TIME * jitter_speed);
    float offset = random(vec2(snapped_time, 0.0));
    
    // 随机偏移顶点位置
    VERTEX.x += (random(vec2(snapped_time, 1.0)) - 0.5) * jitter_amount;
    VERTEX.y += (random(vec2(snapped_time, 2.0)) - 0.5) * jitter_amount;
}
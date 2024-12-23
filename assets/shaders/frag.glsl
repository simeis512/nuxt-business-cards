#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;   // 画面サイズ
uniform float u_aspect;      // アスペクト比
uniform vec3 u_balls[40];    // ボールの位置と半径（x, y, r）
uniform vec3 u_colors[40];   // ボールの色（HSL）
uniform float u_threshold;   // しきい値
uniform float u_blurWidth;   // ぼかしの幅

varying vec2 vTexCoord;

// HSLからRGBに変換
vec3 hsl2rgb(float h, float s, float l) {
    float c = (1.0 - abs(2.0 * l - 1.0)) * s;
    float x = c * (1.0 - abs(mod(h * 6.0, 2.0) - 1.0));
    float m = l - c / 2.0;
    vec3 rgb = vec3(0.0);
    if (0.0 <= h && h < 1.0 / 6.0) rgb = vec3(c, x, 0.0);
    else if (1.0 / 6.0 <= h && h < 2.0 / 6.0) rgb = vec3(x, c, 0.0);
    else if (2.0 / 6.0 <= h && h < 3.0 / 6.0) rgb = vec3(0.0, c, x);
    else if (3.0 / 6.0 <= h && h < 4.0 / 6.0) rgb = vec3(0.0, x, c);
    else if (4.0 / 6.0 <= h && h < 5.0 / 6.0) rgb = vec3(x, 0.0, c);
    else rgb = vec3(c, 0.0, x);
    return rgb + m;
}

void main() {
    vec2 uv = vTexCoord;
    uv.x *= u_aspect;
    float sum = 0.0;     // 影響度の合計
    vec2 hueVec = vec2(0.0); // Hueをベクトルとして合成
    float sTotal = 0.0;  // 彩度の加重合計
    float lTotal = 0.0;  // 明度の加重合計

    for (int i = 0; i < 40; i++) {
        vec2 center = u_balls[i].xy / u_resolution;
        float radius = u_balls[i].z / u_resolution.x;
        float dist = distance(uv, center);

        // 影響度の計算（smoothstepで滑らかに減衰）
        float influence = smoothstep(0.0, 1.0, 1.0 - (dist / radius));
        influence = pow(influence, 2.0); // 非線形補正

        if (influence > 0.0) {
            float angle = u_colors[i].x * 2.0 * 3.14159265;
            hueVec += influence * vec2(cos(angle), sin(angle));
            sTotal += influence * u_colors[i].y;
            lTotal += influence * u_colors[i].z;
            sum += influence;
        }
    }

    // 境界を滑らかにぼかす
    float alpha = smoothstep(u_threshold - u_blurWidth, u_threshold + u_blurWidth, sum);

    if (alpha > 0.01) {
        // Hueの平均を計算
        float avgHue = atan(hueVec.y, hueVec.x) / (2.0 * 3.14159265);
        if (avgHue < 0.0) avgHue += 1.0;

        float avgSaturation = sTotal / sum;
        float avgLightness = lTotal / sum;

        vec3 color = hsl2rgb(avgHue, avgSaturation, avgLightness);
        gl_FragColor = vec4(color, alpha); // アルファでぼかしを適用
    } else {
        gl_FragColor = vec4(1.0, 1.0, 1.0, 0.0); // 背景（透明）
    }
}

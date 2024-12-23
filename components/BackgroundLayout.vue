<template>
  <div ref="canvas" class="flex w-[210mm] h-[297mm] absolute top-0 left-0"></div>
</template>

<script>
import p5 from "p5";
import vertShader from "@/assets/shaders/vert.glsl?raw";
import fragShader from "@/assets/shaders/frag.glsl?raw";

export default {
  mounted() {
    const sketch = (p) => {
      let shaderProgram;
      let balls = [];

      function randomSpeed(min1, max1, min2, max2) {
        return Math.random() < 0.5 ? p.random(min1, max1) : p.random(min2, max2);
      }

      p.preload = () => {
        shaderProgram = p.createShader(vertShader, fragShader);
      };

      p.setup = () => {
        const container = this.$refs.canvas;
        p.createCanvas(container.clientWidth, container.clientHeight, p.WEBGL);
        p.noStroke();

        // ボールデータ生成
        for (let i = 0; i < 40; i++) {
          balls.push({
            x: p.random(p.width),
            y: p.random(p.height),
            r: p.random(120, 180),
            h: p.random(0.4, 0.75), // 色相
            s: p.random(0.84, 0.92), // 彩度
            l: p.random(0.91, 0.96), // 明度
            vx: randomSpeed(-1, -0.2, 0.2, 1),
            vy: randomSpeed(-0.8, -0.2, 0.2, 0.8),
            // vx: 0.0,
            // vy: 0.0
          });
        }
      };

      p.draw = () => {
        p.shader(shaderProgram);
        shaderProgram.setUniform("u_resolution", [p.width, p.height]);
        shaderProgram.setUniform("u_aspect", p.width / p.height);
        shaderProgram.setUniform("u_threshold", 0.6);
        shaderProgram.setUniform("u_blurWidth", 0.4);
        shaderProgram.setUniform("u_time", p.millis() / 1000);

        // ボールデータ更新
        let positions = [];
        let colors = [];
        balls.forEach((ball) => {
          ball.x += ball.vx;
          ball.y += ball.vy;

          if (ball.x < 10 || ball.x > p.width - 10) ball.vx *= -1;
          if (ball.y < 10 || ball.y > p.height - 10) ball.vy *= -1;

          positions.push(ball.x, ball.y, ball.r);
          colors.push(ball.h, ball.s, ball.l);
        });

        shaderProgram.setUniform("u_balls", positions);
        shaderProgram.setUniform("u_colors", colors);

        // rectをキャンバス全体に合わせて描画
        p.rect();
      };
    };
    
    new p5(sketch, this.$refs.canvas);
  },
};
</script>

<style scoped>
.w-full {
  width: 100%;
  height: 100%;
}
</style>
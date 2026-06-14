// 頂点データ
attribute vec3 aPosition;
attribute vec2 aTexCoord;

// p5が渡す変換行列
uniform mat4 uProjectionMatrix;
uniform mat4 uModelViewMatrix;

// テクスチャ座標
varying vec2 vTexCoord;

void main() {
  vTexCoord = aTexCoord;
  gl_Position = uProjectionMatrix * uModelViewMatrix * vec4(aPosition, 1.0);
}

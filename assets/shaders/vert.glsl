// 頂点データ
attribute vec3 aPosition;

// テクスチャ座標
attribute vec2 aTexCoord;
varying vec2 vTexCoord;

void main() {
  // 頂点座標を -1.0 から 1.0 の範囲に変換
  vec4 positionVec4 = vec4(aPosition, 1.0);
  positionVec4.xy = positionVec4.xy * 2.0 - 1.0;

  // テクスチャ座標をフラグメントシェーダーに送る
  vTexCoord = aTexCoord;

  // 最終的な頂点座標
  gl_Position = positionVec4;
}

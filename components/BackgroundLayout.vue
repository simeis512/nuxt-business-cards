<template>
  <div>
    <div ref="canvas" class="flex w-[210mm] h-[297mm] absolute top-0 left-0"></div>

    <!-- 描画中のオーバーレイ。renderAll はメインスレッドを同期ブロックするので、
         先にこれを1フレーム描画させてから重い処理に入る（runBuild 参照）。
         スピナーは transform アニメ＝コンポジタ側で回るので描画中も止まらない。 -->
    <div
      v-if="rendering || exporting"
      data-no-export
      class="fixed inset-0 z-50 flex items-center justify-center bg-white/50 pointer-events-none print:hidden"
    >
      <div class="flex items-center gap-3 rounded-xl bg-black/75 px-5 py-3 text-white text-sm shadow-lg">
        <span class="inline-block w-4 h-4 rounded-full border-2 border-white/30 border-t-white animate-spin"></span>
        {{ exporting ? "画像を保存中…" : "描画中…" }}
      </div>
    </div>

    <!-- 操作ヒント（印刷・PNG書き出しには出さない） -->
    <div data-no-export class="fixed bottom-3 right-3 z-40 rounded-md bg-black/55 px-2.5 py-1 text-[11px] text-white/90 pointer-events-none print:hidden">
      R: 再描画 ／ S: 画像保存(PNG)
    </div>

    <!-- 印刷補正パネル（画面のみ。印刷・PNG書き出しには出さない） -->
    <div
      data-no-export
      class="fixed top-3 left-3 z-40 w-52 rounded-lg bg-black/70 p-3 text-[11px] text-white pointer-events-auto print:hidden"
      :class="{ 'space-y-2': panelOpen }"
    >
      <!-- ヘッダー：クリックで開閉 -->
      <div class="flex cursor-pointer select-none items-center justify-between" @click="togglePanel">
        <span class="font-bold">印刷補正（背景のみ）</span>
        <span class="ml-2 opacity-80">{{ panelOpen ? "▲" : "▼" }}</span>
      </div>
      <template v-if="panelOpen">
        <label class="block">
          <div class="flex justify-between"><span>彩度</span><span>{{ satur.toFixed(2) }}</span></div>
          <input v-model.number="satur" type="range" min="0.5" max="2" step="0.01" class="w-full" />
        </label>
        <label class="block">
          <div class="flex justify-between"><span>明度</span><span>{{ bright.toFixed(3) }}</span></div>
          <!-- 明度は1.0付近で白飛びしやすいので範囲を狭め分解能を上げる -->
          <input v-model.number="bright" type="range" min="0.85" max="1.15" step="0.002" class="w-full" />
        </label>
        <label class="block">
          <div class="flex justify-between"><span>コントラスト</span><span>{{ contrast.toFixed(2) }}</span></div>
          <input v-model.number="contrast" type="range" min="0.5" max="1.5" step="0.01" class="w-full" />
        </label>
        <div class="flex gap-2 pt-1">
          <button class="rounded bg-white/15 px-2 py-1 hover:bg-white/25" @click="resetAdjust">
            リセット
          </button>
          <!-- 押している間だけ無補正（デフォルト）を表示して比較 -->
          <button
            class="flex-1 select-none rounded py-1"
            :class="previewDefault ? 'bg-amber-400/70 text-black' : 'bg-white/15 hover:bg-white/25'"
            @mousedown="setPreviewDefault(true)"
            @mouseup="setPreviewDefault(false)"
            @mouseleave="setPreviewDefault(false)"
            @touchstart.prevent="setPreviewDefault(true)"
            @touchend="setPreviewDefault(false)"
          >
            {{ previewDefault ? "元の色を表示中…" : "長押しで元の色" }}
          </button>
        </div>
      </template>
    </div>
  </div>
</template>

<script>
import p5 from "p5";
import vertShader from "@/assets/shaders/vert.glsl?raw";
import fragShader from "@/assets/shaders/frag.glsl?raw";

// ---- メタボールの調整パラメータ -------------------------------------------
const THRESHOLD = 0.6;      // しきい値
const BLUR_WIDTH = 0.08;    // 輪郭のソフトさ（小さいほどエッジが立つ）
const FROST_BLUR_PX = 0.5;  // すりガラスのぼかし量(px)。0なら完全に透明な板
const FROST_WHITE = 0.35;   // すりガラスの白み（テキスト/イラスト面）
const QR_FROST_WHITE = 0.0; // QR面は自前の白背景(#FFF4)があるので、フロスト側の白は無し
const QR_RADIUS = 18;       // QR背景の角丸（150px基準。QRCodeGeneratorStyling の rx と一致）

// 凸レンズ風の屈折：プレート形状をぼかしたマスクで「縁の帯」を求め、
// その帯だけ背景を中心方向に拡大サンプリングする。中央は素通し（透明な板）、
// 丸い縁だけが凸レンズのように背景を拡大・湾曲させる。
const LENS_EDGE = 3;       // 縁のレンズ帯の幅(px)。大きいほどなだらかで広いレンズ
const LENS_MAG = 0.1;      // 縁での拡大の強さ（中心方向へ引き込む割合）
const DISP_MARGIN = 40;    // レンズで外側からサンプルするぶんの余白(px)

// ハイライト：縁から LENS_EDGE 内側のライン上に、11時方向の光で発光する細い線。
// 白背景では見えず、メタボールが裏に来たときに光って見える。
const HILIGHT_A = 0.9;     // ハイライトの強さ(0〜1)
const HILIGHT_T = 0.4;     // ラインが乗るマスク値（縁からLENS_EDGE内側≒0.8）
const HILIGHT_BAND = 0.22; // ラインの太さ（マスク値の許容幅）

// ドロップシャドウ：板の存在感をかすかに高める薄い影
const DROP_A = 0.04;       // 影の濃さ(0〜1)
const DROP_DX = 1;         // 影のオフセットx(px)
const DROP_DY = 1;         // 影のオフセットy(px)
const DROP_BLUR = 2;       // 影のぼかし(px)

const R_MIN = 100;         // ボール半径(px)
const R_MAX = 125;
const MAX_BALLS = 128;     // シェーダー側の上限と一致させる
const ANCHOR_JIT = 8;      // 固定アンカーのばらけ幅(px)

// 印刷用の内部解像度倍率。表示サイズ(mm)は据え置き、canvasのピクセル数だけ増やす。
// 大きいほど高精細だが、初期化が SCALE² で重くなる。既定3(≒288dpi)。
// 書き出し時だけ URL の ?scale=4〜5(≒384〜480dpi) で高精細化できる（1〜6でクランプ）。
const SCALE = (() => {
  if (typeof window === "undefined") return 3;
  const m = window.location.search.match(/[?&]scale=([\d.]+)/);
  const v = m ? parseFloat(m[1]) : NaN;
  return Number.isFinite(v) ? Math.min(6, Math.max(1, v)) : 3;
})();

// 占有率の目標レンジ（カード面積に対するメタボールの割合）
const OCC_MIN = 0.22;
const OCC_MAX = 0.38;

const smoothstep = (a, b, x) => {
  const t = Math.min(Math.max((x - a) / (b - a), 0), 1);
  return t * t * (3 - 2 * t);
};

export default {
  data() {
    // 印刷補正：彩度/明度/コントラスト（1.0=無補正）。背景canvasのみにCSS filterで適用。
    // previewDefault=長押し中だけ無補正にして元の色と比較する。
    return { rendering: false, exporting: false, satur: 1, bright: 1, contrast: 1, previewDefault: false, panelOpen: true };
  },
  computed: {
    adjustFilter() {
      return `saturate(${this.satur}) brightness(${this.bright}) contrast(${this.contrast})`;
    },
    adjustActive() {
      return this.satur !== 1 || this.bright !== 1 || this.contrast !== 1;
    },
  },
  watch: {
    adjustFilter() {
      this.applyAdjust();
    },
    previewDefault() {
      this.applyAdjust();
    },
  },
  methods: {
    // 印刷補正を「背景canvasのみ」に適用（文字/QR/イラストは非補正）。値はlocalStorageに保存。
    applyAdjust(tries = 0) {
      if (tries === 0) {
        try {
          localStorage.setItem(
            "cardAdjust",
            JSON.stringify({ s: this.satur, b: this.bright, c: this.contrast })
          );
        } catch (e) { /* localStorage不可でも無視 */ }
      }
      const cv = this.$refs.canvas && this.$refs.canvas.querySelector("canvas");
      if (!cv) {
        // 背景canvasがまだ生成されていなければ少し待って再適用
        if (tries < 60) requestAnimationFrame(() => this.applyAdjust(tries + 1));
        return;
      }
      // 長押し比較中(previewDefault)は無補正で表示
      cv.style.filter = this.adjustActive && !this.previewDefault ? this.adjustFilter : "";
    },
    resetAdjust() {
      this.satur = 1;
      this.bright = 1;
      this.contrast = 1;
    },
    // 比較ボタン：押している間だけデフォルト（無補正）を表示
    setPreviewDefault(v) {
      this.previewDefault = v;
    },
    // 補正パネルの開閉。状態はlocalStorageに保存
    togglePanel() {
      this.panelOpen = !this.panelOpen;
      try {
        localStorage.setItem("cardPanelOpen", this.panelOpen ? "1" : "0");
      } catch (e) { /* 無視 */ }
    },
    // Sキー：ブラウザの合成器でA4全面(背景canvas＋カードDOM)をPNG化して保存。
    // ChromeのPDF保存→GIMP(poppler)で起きる暗転問題を回避するための書き出し経路。
    async exportPng() {
      if (this.exporting || this.rendering) return;
      this.exporting = true;
      try {
        const { default: html2canvas } = await import("html2canvas");
        if (document.fonts && document.fonts.ready) await document.fonts.ready;
        await this.$nextTick();
        // 「保存中…」を1フレーム描画させてから重い合成に入る
        await new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r)));
        const target = document.querySelector(".print-page") || this.$refs.canvas;
        const bgCanvas = this.$refs.canvas.querySelector("canvas");
        // .print-page は子が全て絶対配置で高さ0になるため、A4実寸(背景canvasのCSSサイズ)を明示。
        const w = bgCanvas ? bgCanvas.clientWidth : Math.round(210 * (96 / 25.4));
        const h = bgCanvas ? bgCanvas.clientHeight : Math.round(297 * (96 / 25.4));
        // 補正は「背景canvasのみ」。html2canvasはCSS filter非対応なので、捕捉前に
        // 背景canvasのピクセルへ補正を焼き込み（カードは非補正のまま）、捕捉後に元へ戻す。
        const prevCss = bgCanvas ? bgCanvas.style.filter : "";
        let orig = null;
        if (bgCanvas && this.adjustActive && !this.previewDefault) {
          orig = document.createElement("canvas");
          orig.width = bgCanvas.width;
          orig.height = bgCanvas.height;
          orig.getContext("2d").drawImage(bgCanvas, 0, 0);
          const bctx = bgCanvas.getContext("2d");
          bctx.save();
          bctx.setTransform(1, 0, 0, 1, 0, 0);
          bctx.clearRect(0, 0, bgCanvas.width, bgCanvas.height);
          bctx.filter = this.adjustFilter;
          bctx.drawImage(orig, 0, 0);
          bctx.filter = "none";
          bctx.restore();
        }
        if (bgCanvas) bgCanvas.style.filter = ""; // 画面のCSS filterは捕捉に効かないが念のため外す
        let raw;
        try {
          raw = await html2canvas(target, {
            backgroundColor: "#ffffff",
            scale: SCALE, // ?scale=N と連動した高DPI（既定3）
            useCORS: true,
            logging: false,
            width: w,
            height: h,
            windowWidth: Math.max(document.documentElement.clientWidth, w),
            windowHeight: Math.max(document.documentElement.clientHeight, h),
            ignoreElements: (el) => el.hasAttribute && el.hasAttribute("data-no-export"),
          });
        } finally {
          // 背景canvasのピクセルとCSS filterを元へ戻す
          if (orig && bgCanvas) {
            const bctx = bgCanvas.getContext("2d");
            bctx.save();
            bctx.setTransform(1, 0, 0, 1, 0, 0);
            bctx.clearRect(0, 0, bgCanvas.width, bgCanvas.height);
            bctx.drawImage(orig, 0, 0);
            bctx.restore();
          }
          if (bgCanvas) bgCanvas.style.filter = prevCss;
        }
        const a = document.createElement("a");
        a.href = raw.toDataURL("image/png");
        a.download = `business-cards@${SCALE}x.png`;
        document.body.appendChild(a);
        a.click();
        a.remove();
      } catch (err) {
        console.error("PNG export failed:", err);
      } finally {
        this.exporting = false;
      }
    },
  },
  beforeUnmount() {
    if (this._onKey) window.removeEventListener("keydown", this._onKey);
    if (this._p5) this._p5.remove();
  },
  mounted() {
    // ?debug / ?debug=1 → 矩形・占有率オーバーレイ、?debug=2 → 背景にグリッド（屈折の確認用）
    const DEBUG = (() => {
      if (typeof window === "undefined") return 0;
      const m = window.location.search.match(/[?&]debug(?:=(\d+))?/);
      if (!m) return 0;
      return m[1] ? parseInt(m[1], 10) : 1;
    })();

    const sketch = (p) => {
      let shaderProgram;
      let webglGfx; // シェーダー描画用（WEBGL）
      let bg;       // メタボールの合成（シャープ／P2D）
      let bgData;   // bg のピクセル（屈折のサンプリング元）

      let W = 0;
      let H = 0;
      let balls = [];
      let plates = [];        // 各カードのテキストプレート矩形（canvas座標, px）
      let imagePlates = [];   // 各カードのイラストプレート矩形
      let cards = [];         // カード矩形（canvas座標, px）
      let qrRects = [];       // 各カードのQRのAABB
      let frostRegions = [];  // ぼかしを焼き込む全領域（テキスト/イラスト/QR）

      const rand = (a, b) => a + Math.random() * (b - a);

      // SCALEを反映したピクセル系の値（座標を高解像度化したぶん、サイズ系も倍にする）
      const sRMin = R_MIN * SCALE;
      const sRMax = R_MAX * SCALE;
      const sJit = ANCHOR_JIT * SCALE;
      const sLensEdge = LENS_EDGE * SCALE;
      const sDispMargin = DISP_MARGIN * SCALE;
      const sFrostBlur = FROST_BLUR_PX * SCALE;
      const sDropDx = DROP_DX * SCALE;
      const sDropDy = DROP_DY * SCALE;
      const sDropBlur = DROP_BLUR * SCALE;

      // 原点中心の角丸正方形パス（QRの丸角に合わせる）
      const roundedRectPath = (side, r) => {
        const h = side / 2;
        const path = new Path2D();
        path.moveTo(-h + r, -h);
        path.lineTo(h - r, -h);
        path.arcTo(h, -h, h, -h + r, r);
        path.lineTo(h, h - r);
        path.arcTo(h, h, h - r, h, r);
        path.lineTo(-h + r, h);
        path.arcTo(-h, h, -h, h - r, r);
        path.lineTo(-h, -h + r);
        path.arcTo(-h, -h, -h + r, -h, r);
        path.closePath();
        return path;
      };

      const clipToCard = (ctx, card) => {
        if (!card) return;
        ctx.beginPath();
        ctx.rect(card.x, card.y, card.w, card.h);
        ctx.clip();
      };

      // --- JS側のフィールド評価（シェーダーと同じロジックを粗く再現）---------
      const fieldSum = (px, py) => {
        let sum = 0;
        for (const b of balls) {
          const dist = Math.hypot(px - b.x, py - b.y);
          let inf = smoothstep(0, 1, 1 - dist / b.r);
          inf = inf * inf;
          sum += inf;
        }
        return sum;
      };
      const isMeta = (px, py) =>
        smoothstep(THRESHOLD - BLUR_WIDTH, THRESHOLD + BLUR_WIDTH, fieldSum(px, py)) > 0.5;

      // --- DOMからプレート／カードの位置を実測 --------------------------------
      const acquireRects = () => {
        const canvasRect = p.canvas.getBoundingClientRect();
        // getBoundingClientRectはCSS px。SCALE倍してビットマップ座標に変換する。
        const toLocal = (el) => {
          const r = el.getBoundingClientRect();
          return {
            x: (r.left - canvasRect.left) * SCALE,
            y: (r.top - canvasRect.top) * SCALE,
            w: r.width * SCALE,
            h: r.height * SCALE,
          };
        };

        cards = [...document.querySelectorAll("[data-card]")].map(toLocal);

        // 配置基準のプレート（カードごと1枚ずつ）。アンカー配置に使う
        plates = [...document.querySelectorAll('[data-plate-role="text"]')].map(toLocal);
        imagePlates = [...document.querySelectorAll('[data-plate-role="image"]')].map(toLocal);

        frostRegions = [];

        // 焼き込む領域：テキスト＋イラスト（形状はdata属性のpath/viewBox）
        [...document.querySelectorAll("[data-glass-plate]")].forEach((el) => {
          const [vw, vh] = el.dataset.plateVb.split(/\s+/).map(Number);
          const rect = toLocal(el);
          const cardEl = el.closest("[data-card]");
          const path = new Path2D(el.dataset.platePath);
          frostRegions.push({
            card: cardEl ? toLocal(cardEl) : null,
            white: FROST_WHITE,
            path,
            aabb: rect,
            center: { cx: rect.x + rect.w / 2, cy: rect.y + rect.h / 2 },
            // クリップ用の座標変換（inset でプレート中心に向けて縮小）
            applyTransform: (ctx, inset) => {
              ctx.translate(rect.x, rect.y);
              ctx.scale(rect.w / vw, rect.h / vh);
              if (inset !== 1) {
                ctx.translate(vw / 2, vh / 2);
                ctx.scale(inset, inset);
                ctx.translate(-vw / 2, -vh / 2);
              }
            },
          });
        });

        // QR：回転した角丸正方形。#qr のAABBから一辺と角丸を逆算
        qrRects = [];
        [...document.querySelectorAll("#qr")].forEach((el) => {
          const rect = toLocal(el);
          qrRects.push(rect);
          const cardEl = el.closest("[data-card]");
          const cx = rect.x + rect.w / 2;
          const cy = rect.y + rect.h / 2;
          const side = rect.w / Math.SQRT2;          // 45°回転した正方形の一辺
          const r = (QR_RADIUS * side) / 150;        // rxは150px基準なのでスケール
          frostRegions.push({
            card: cardEl ? toLocal(cardEl) : null,
            white: QR_FROST_WHITE,
            path: roundedRectPath(side, r),
            aabb: rect,
            center: { cx, cy },
            applyTransform: (ctx, inset) => {
              ctx.translate(cx, cy);
              ctx.rotate(Math.PI / 4);
              if (inset !== 1) ctx.scale(inset, inset);
            },
          });
        });
      };

      // 各カードに必ず入れる色相帯：緑・水色・紫。
      const HUE_BANDS = [
        [0.36, 0.44], // 緑
        [0.49, 0.56], // 水色
        [0.72, 0.78], // 紫
      ];
      const pickHue = (band) => rand(band[0], band[1]);
      const shuffleInPlace = (arr) => {
        for (let k = arr.length - 1; k > 0; k--) {
          const j = Math.floor(Math.random() * (k + 1));
          [arr[k], arr[j]] = [arr[j], arr[k]];
        }
        return arr;
      };
      // 緑・水色・紫を必ず1つずつ含め、残りはランダムな帯から補い、順番をシャッフルする。
      // これで「3色は必ず入る」かつ「位置（順番）はカードごとに変わる」を両立する。
      const buildCardHues = (n) => {
        const hues = HUE_BANDS.map(pickHue);
        while (hues.length < n) {
          hues.push(pickHue(HUE_BANDS[Math.floor(Math.random() * HUE_BANDS.length)]));
        }
        return shuffleInPlace(hues);
      };

      // --- 固定アンカーによるメタボール配置 ----------------------------------
      // 各カードに6つの定位置（少しばらけさせる）。各アンカーは
      // 「主ボール＋周囲に小ボール1つ」で構成する。色相はカードごとに
      // 緑・水色・紫を必ず含み、順番はシャッフルしてカード差を出す。
      const placeBalls = () => {
        balls = [];
        const jit = () => rand(-sJit, sJit);

        cards.forEach((c, i) => {
          const tp = plates[i];
          const ip = imagePlates[i];
          const q = qrRects[i];
          if (!tp || !ip || !q) return;

          const anchors = [
            { x: q.x + q.w * 0.28, y: q.y + q.h * 0.28 },     // QR 左上
            { x: q.x + q.w * 0.72, y: q.y + q.h * 0.26 },     // QR 右上
            { x: q.x + q.w * 0.42, y: q.y + q.h * 0.62 },     // QR 左下
            { x: tp.x + tp.w * 0.47, y: tp.y + tp.h * 0.60 }, // 名前 中央やや左下
            { x: ip.x + ip.w * 0.35, y: ip.y + ip.h * 0.75 }, // イラスト やや下
            { x: ip.x + ip.w * 0.75, y: ip.y + ip.h * 0.25 }, // イラスト 右上
          ];

          // このカードの色相（緑・水色・紫を必ず含み、順番はシャッフル済み）
          const hues = buildCardHues(anchors.length);

          anchors.forEach((an, ai) => {
            const mainR = rand(sRMin, sRMax);
            const mx = an.x + jit();
            const my = an.y + jit();
            const h = hues[ai];
            let sl = slFromHue(h);
            balls.push({ x: mx, y: my, r: mainR, h, s: sl.s, l: sl.l });
            // 周囲に小さいメタボールを1つ（主ボールと同系色・重なる近さ・少しばらけ）
            const ang = rand(0, Math.PI * 2);
            const d = mainR * rand(0.25, 0.3);
            const sh = Math.min(0.82, Math.max(0.34, h + rand(-0.02, 0.02)));
            sl = slFromHue(sh);
            balls.push({
              x: mx + Math.cos(ang) * d,
              y: my + Math.sin(ang) * d,
              r: mainR * rand(0.2, 0.3),
              h: sh,
              s: sl.s,
              l: sl.l,
            });
          });
        });

        balls = balls.slice(0, MAX_BALLS);
      };

      // 色相hに応じてs/lを決める。基本は修正前の色味（緑は濃いめ、紫は彩度
      // 控えめでやわらかい）。ただし紫が白飛びしないよう、明度の振れ幅だけ
      // 狭める（旧:+0.1*ht=最大l0.96 → +0.04*ht=最大l約0.92）。
      const slFromHue = (h) => {
        const ht = Math.min(1, Math.max(0, (h - 0.4) / 0.35)); // 0:緑 1:紫
        return {
          s: 0.94 - 0.18 * ht + rand(-0.02, 0.02), // 緑は濃く、青紫は控えめ（修正前どおり）
          l: 0.86 + 0.04 * ht + rand(-0.02, 0.02), // 紫の明るさ上限を抑えて白飛び回避
        };
      };

      // 占有率を計測（カードごと）。step刻みでサンプリング
      const measure = () => {
        const step = 7;
        return cards.map((c, idx) => {
          const pl = plates[idx];
          let total = 0;
          let meta = 0;
          let glassMeta = 0;
          let nonGlassMeta = 0;
          for (let y = c.y; y < c.y + c.h; y += step) {
            for (let x = c.x; x < c.x + c.w; x += step) {
              total++;
              const m = isMeta(x, y);
              if (m) meta++;
              const inPlate =
                pl && x >= pl.x && x <= pl.x + pl.w && y >= pl.y && y <= pl.y + pl.h;
              if (inPlate) { if (m) glassMeta++; }
              else if (m) nonGlassMeta++;
            }
          }
          return {
            occ: meta / total,
            glassOK: glassMeta > 0,
            nonGlassOK: nonGlassMeta > 0,
          };
        });
      };

      // 1領域分を凸レンズ風に屈折させて焼き込む
      const frostOne = (reg) => {
        const ctx = p.drawingContext;
        const a = reg.aabb;
        const ex = Math.max(0, Math.floor(a.x - sDispMargin));
        const ey = Math.max(0, Math.floor(a.y - sDispMargin));
        const ew = Math.min(W, Math.ceil(a.x + a.w + sDispMargin)) - ex;
        const eh = Math.min(H, Math.ceil(a.y + a.h + sDispMargin)) - ey;
        if (ew <= 2 || eh <= 2) return;

        // 1) プレート形状をぼかしたマスク。縁にだけ勾配が立つ＝レンズの法線源
        const mc = document.createElement("canvas");
        mc.width = ew;
        mc.height = eh;
        const mx = mc.getContext("2d");
        mx.fillStyle = "#000";
        mx.fillRect(0, 0, ew, eh);
        mx.filter = `blur(${sLensEdge}px)`;
        mx.fillStyle = "#fff";
        mx.translate(-ex, -ey);
        reg.applyTransform(mx, 1);
        mx.fill(reg.path);
        const mask = mx.getImageData(0, 0, ew, eh).data;

        // 2) 縁の帯だけ、背景を中心方向に拡大サンプリングして凸レンズ屈折を作る
        const out = ctx.createImageData(ew, eh);
        const od = out.data;
        const bd = bgData.data;
        const cxp = reg.center.cx;
        const cyp = reg.center.cy;
        for (let y = 0; y < eh; y++) {
          for (let x = 0; x < ew; x++) {
            const i = y * ew + x;
            const t = mask[i * 4] / 255; // 0:外 1:内、縁で0→1に遷移
            const w = t * (1 - t) * 4;   // 縁の帯で最大(=1)、中央/外で0
            const px = ex + x;
            const py = ey + y;
            let sx = px;
            let sy = py;
            if (w > 0.01) {
              const m = LENS_MAG * w; // 縁ほど中心方向へ引き込む＝拡大
              sx = px - (px - cxp) * m;
              sy = py - (py - cyp) * m;
              sx = sx < 0 ? 0 : sx > W - 1 ? W - 1 : sx;
              sy = sy < 0 ? 0 : sy > H - 1 ? H - 1 : sy;
            }
            const si = ((sy | 0) * W + (sx | 0)) * 4;
            const di = i * 4;
            od[di] = bd[si];
            od[di + 1] = bd[si + 1];
            od[di + 2] = bd[si + 2];
            od[di + 3] = 255;

            // 縁からLENS_EDGE内側のライン上で、11時方向の光に向く面だけ発光させる
            if (x > 0 && x < ew - 1 && y > 0 && y < eh - 1) {
              const gx = mask[(i + 1) * 4] - mask[(i - 1) * 4];
              const gy = mask[(i + ew) * 4] - mask[(i - ew) * 4];
              const gmag = Math.hypot(gx, gy);
              if (gmag > 0.5) {
                // 外向き法線(=-勾配)と11時方向(-0.5,-0.866)の内積 → 受光面で>0
                const dir = (gx * 0.5 + gy * 0.866) / gmag;
                if (dir > 0) {
                  // 縁からLENS_EDGE内側≒マスク値HILIGHT_T のライン上で最大
                  const d = (t - HILIGHT_T) / HILIGHT_BAND;
                  const lineW = Math.exp(-d * d);
                  const spec = dir * lineW * HILIGHT_A;
                  od[di] += (255 - od[di]) * spec;
                  od[di + 1] += (255 - od[di + 1]) * spec;
                  od[di + 2] += (255 - od[di + 2]) * spec;
                }
              }
            }
          }
        }

        // 2b) ドロップシャドウ（板の存在感をかすかに）。本体の前に薄く落とす
        ctx.save();
        clipToCard(ctx, reg.card);
        ctx.translate(sDropDx, sDropDy);
        reg.applyTransform(ctx, 1);
        ctx.filter = `blur(${sDropBlur}px)`;
        ctx.fillStyle = `rgba(20,30,50,${DROP_A})`;
        ctx.fill(reg.path);
        ctx.filter = "none";
        ctx.restore();

        // 3) temp canvas に出力 → プレート形状にクリップして（軽くぼかして）焼き込む
        const tc = document.createElement("canvas");
        tc.width = ew;
        tc.height = eh;
        tc.getContext("2d").putImageData(out, 0, 0);

        ctx.save();
        clipToCard(ctx, reg.card);
        reg.applyTransform(ctx, 1);
        ctx.clip(reg.path);
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        if (sFrostBlur > 0) ctx.filter = `blur(${sFrostBlur}px)`;
        ctx.drawImage(tc, ex, ey);
        ctx.filter = "none";
        if (reg.white > 0) {
          ctx.fillStyle = `rgba(255,255,255,${reg.white})`;
          ctx.fillRect(0, 0, W, H);
        }
        ctx.restore();
      };

      // --- 全体描画（一度きり）------------------------------------------------
      const renderAll = () => {
        // メタボールをシェーダーで描画
        const flatBalls = [];
        const flatColors = [];
        balls.forEach((b) => {
          flatBalls.push(b.x, b.y, b.r);
          flatColors.push(b.h, b.s, b.l);
        });
        webglGfx.clear();
        webglGfx.shader(shaderProgram);
        shaderProgram.setUniform("u_resolution", [W, H]);
        shaderProgram.setUniform("u_threshold", THRESHOLD);
        shaderProgram.setUniform("u_blurWidth", BLUR_WIDTH);
        shaderProgram.setUniform("u_count", balls.length);
        shaderProgram.setUniform("u_balls", flatBalls);
        shaderProgram.setUniform("u_colors", flatColors);
        webglGfx.noStroke();
        webglGfx.plane(W, H);

        // シャープな背景を合成（白地＋メタボール）
        bg.clear();
        bg.background(255);
        bg.image(webglGfx, 0, 0, W, H);

        // debug=2: 背景にグリッドを重ねる（直線が歪むので屈折が分かりやすい）
        if (DEBUG >= 2) {
          bg.push();
          bg.stroke(40, 60, 90, 110);
          bg.strokeWeight(SCALE);
          const step = 24 * SCALE;
          for (let x = 0; x <= W; x += step) bg.line(x, 0, x, H);
          for (let y = 0; y <= H; y += step) bg.line(0, y, W, y);
          bg.pop();
        }

        // メイン＝シャープ背景
        p.clear();
        p.background(255);
        p.image(bg, 0, 0, W, H);

        // 屈折のサンプリング元としてbgのピクセルを一度だけ取得
        bgData = bg.drawingContext.getImageData(0, 0, W, H);

        // 各プレート形状に、凸レンズ屈折＋（軽い）ぼかし＋リムを焼き込む
        frostRegions.forEach(frostOne);

        if (DEBUG === 1) drawDebug();
      };

      const drawDebug = () => {
        const stats = measure();
        p.push();
        p.textSize(11);
        p.textAlign(p.LEFT, p.TOP);
        cards.forEach((c, i) => {
          const s = stats[i];
          p.noFill();
          p.stroke(255, 0, 0, 120);
          p.rect(c.x, c.y, c.w, c.h);
          const pl = plates[i];
          if (pl) {
            p.stroke(0, 120, 255, 160);
            p.rect(pl.x, pl.y, pl.w, pl.h);
          }
          p.noStroke();
          p.fill(0);
          const occPct = Math.round(s.occ * 100);
          const flag = `${s.glassOK ? "G" : "g"}${s.nonGlassOK ? "N" : "n"}`;
          p.text(`${occPct}% ${flag}`, c.x + 3, c.y + 3);
        });
        p.pop();
      };

      // --- プレート/QRが描画されるのを待ってから構築 ------------------------
      const waitForPlates = (tries = 0) => {
        const cardN = document.querySelectorAll("[data-card]").length;
        const textN = document.querySelectorAll('[data-plate-role="text"]').length;
        const qrN = document.querySelectorAll("#qr svg").length; // QR本体が描画済みか
        if (cardN > 0 && textN === cardN && qrN === cardN) {
          runBuild();
        } else if (tries < 180) {
          requestAnimationFrame(() => waitForPlates(tries + 1));
        } else if (textN > 0) {
          runBuild();
        }
      };

      // 「描画中…」を確実に1フレーム表示してから、同期ブロックする重い描画を走らせる。
      // nextTick でDOM反映 → 二重rAFでブラウザに実描画を1回させる → 構築。
      const runBuild = async () => {
        if (this.rendering) return; // 多重実行を防ぐ
        this.rendering = true;
        await this.$nextTick();
        await new Promise((res) =>
          requestAnimationFrame(() => requestAnimationFrame(res))
        );
        try {
          acquireRects();
          placeBalls();
          renderAll();
        } finally {
          this.rendering = false;
        }
      };

      // Rキーからの再描画用に公開（新しい乱数シードで配置し直す）
      this._rebuild = runBuild;

      p.setup = () => {
        p.pixelDensity(1);
        const container = this.$refs.canvas;
        const cssW = container.clientWidth;
        const cssH = container.clientHeight;
        W = Math.round(cssW * SCALE);
        H = Math.round(cssH * SCALE);
        p.createCanvas(W, H);
        // 表示は元のサイズ(mm)のまま。ビットマップだけ高解像度にする。
        p.canvas.style.width = `${cssW}px`;
        p.canvas.style.height = `${cssH}px`;
        p.noLoop(); // 背景は固定。描画は手動で一度だけ。

        webglGfx = p.createGraphics(W, H, p.WEBGL);
        webglGfx.pixelDensity(1);
        shaderProgram = webglGfx.createShader(vertShader, fragShader);

        bg = p.createGraphics(W, H);
        bg.pixelDensity(1);

        waitForPlates();
      };
    };

    this._p5 = new p5(sketch, this.$refs.canvas);

    // R: 再描画 ／ S: PNG保存（入力欄にフォーカス中や修飾キー併用時は無視）
    this._onKey = (e) => {
      if (e.ctrlKey || e.metaKey || e.altKey) return;
      const t = e.target;
      if (t && (t.tagName === "INPUT" || t.tagName === "TEXTAREA" || t.isContentEditable)) return;
      if (e.key === "r" || e.key === "R") {
        this._rebuild && this._rebuild();
      } else if (e.key === "s" || e.key === "S") {
        this.exportPng();
      }
    };
    window.addEventListener("keydown", this._onKey);

    // 保存済みの印刷補正・パネル開閉状態を復元して適用
    try {
      const j = JSON.parse(localStorage.getItem("cardAdjust"));
      if (j) {
        this.satur = j.s ?? 1;
        this.bright = j.b ?? 1;
        this.contrast = j.c ?? 1;
      }
      const o = localStorage.getItem("cardPanelOpen");
      if (o !== null) this.panelOpen = o === "1";
    } catch (e) { /* 無視 */ }
    this.$nextTick(() => this.applyAdjust());
  },
};
</script>

<style scoped>
.w-full {
  width: 100%;
  height: 100%;
}
</style>

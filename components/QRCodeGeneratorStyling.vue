<template>
  <div class="relative w-fit">
    <div class="absolute inset-0 flex justify-center items-center opacity-60">
      <!-- 背景プレート: QRの拡縮(QR_SCALE)に依存しない固定サイズ。中央はNFC枠の形にくり抜く -->
      <!-- svgを直接flex子にすると0幅コンテナで潰れるため、固定サイズのブロックdivで包む -->
      <div class="absolute inset-0 flex justify-center items-center">
        <div
          data-qr-plate
          class="w-[150px] h-[150px] shrink-0"
          :style="{ transform: 'scale(' + plateScale + ')' }"
        >
          <svg width="150" height="150" viewBox="0 0 150 150" xmlns="http://www.w3.org/2000/svg">
            <defs>
              <mask :id="plateMaskId" maskUnits="userSpaceOnUse" x="0" y="0" width="150" height="150">
                <rect x="0" y="0" width="150" height="150" rx="18" fill="white" />
                <rect :x="nfc.x" :y="nfc.y" :width="nfc.w" :height="nfc.h" :rx="nfc.r" :ry="nfc.r"
                  fill="black" transform="rotate(-45 75 75)" />
              </mask>
            </defs>
            <rect x="0" y="0" width="150" height="150" rx="18" fill="#FFF4" :mask="`url(#${plateMaskId})`" />
          </svg>
        </div>
      </div>
      <div class="absolute inset-0 flex justify-center items-center" :style="{ transform: 'scale(' + qrScale + ')' }">
        <div ref="qrCode" id="qr" class="-rotate-90 " />
      </div>
      <div class="absolute inset-0 flex justify-center items-center">
        <div class="absolute flex justify-center items-center w-[9mm] h-[19mm] rounded-[1mm] bg-transparent -rotate-45">
          <div class="absolute left-[1.5mm] top-[1.2mm] scale-[.8]">
          <!-- https://iconduck.com/icons/90434/nfc-variant-off -->
            <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
              <path
                d="m1.25 2.05 20.7 20.7-1.25 1.25-2-2h-14.7a2 2 0 0 1 -2-2v-14.7l-2-2zm2.56-.05h.19 16c1.11 0 2 .89 2 2v16 .19l-2-1.99v-14.2h-14.2zm2.19 7.3-2-2v12.7h12.7l-2-2h-8.7zm12 6.9-2-2v-6.2h-3v2.28c.6.34 1 .98 1 1.72v.19l-3-2.99v-1.2a2 2 0 0 1 2-2h5zm-10-.2h4.7l-4.7-4.7zm2-8h-.2l-2-2h2.2z"
                fill="#013A"
              />
            </svg>
          </div>
        </div>
      </div>
    </div>
    <div class="absolute inset-0 flex justify-center items-center zen-maru-gothic-medium text-lg text-center text-[#013] opacity-60 translate-y-[21.2mm] scale-[0.6]">
      {{ data }}
    </div>
  </div>
</template>

<script>
import QRCodeStyling from "qr-code-styling";

// 表示倍率。どちらも基準サイズ(150)からのCSS transform倍率で、互いに独立して任意に指定できる。
// qr-code-stylingのwidth/heightは内部で量子化され微調整できないため、ここで連続的に拡縮する。
// 1=基準, <1で小さく, >1で大きく。NFC貼り付けエリアはどちらの倍率でも物理サイズ固定。
const QR_SCALE = 0.85;    // QRコード(ドット/コーナー)の倍率
const PLATE_SCALE = 1.0;    // 背景プレート(#FFF4)の倍率
const U = 96 / 25.4; // 1mm をpx(=viewBox unit)へ。96dpi基準
const NFC_W = 8.7;   // NFC枠 横(mm)
const NFC_H = 18.7;  // NFC枠 縦(mm)
const NFC_R = 1;     // 角丸(mm)

export default {
  props: {
    data: { type: String, required: true },
  },
  data() {
    return {
      plateMaskId: 'nfc-plate-' + Math.random().toString(36).slice(2, 9),
    };
  },
  // 倍率系はcomputedにする(data()はHMRで再実行されず定数変更が反映されないため)。
  computed: {
    qrScale: () => QR_SCALE,
    plateScale: () => PLATE_SCALE,
    // 背景プレートのNFCくり抜き矩形(150px基準・中央)。プレートはCSS回転しないので-45°で配置。
    // プレートをCSSでPLATE_SCALE倍するため、くり抜きは1/PLATE_SCALEし物理サイズを固定する。
    nfc() {
      const w = (NFC_W * U) / PLATE_SCALE;
      const h = (NFC_H * U) / PLATE_SCALE;
      return { x: 75 - w / 2, y: 75 - h / 2, w, h, r: (NFC_R * U) / PLATE_SCALE };
    },
  },
  mounted() {
    const qrCode = new QRCodeStyling({
      width: 150,
      height: 150,
      type: 'svg',
      data: this.data,
      dotsOptions: { color: '#013', type: 'dots' },
      cornersSquareOptions: { color: '#013', type: 'extra-rounded' },
      backgroundOptions: { color: 'transparent' }, // プレートは別SVGで描くのでQR自体は透明
      qrOptions: { errorCorrectionLevel: 'H' },
    });
    qrCode.append(this.$refs.qrCode);
    this.applyNfcMask();
  },
  methods: {
    // 中央のNFC貼り付け枠（9mm×19mm 角丸1mm）の形にQRをくり抜く。
    // QRの<svg>(viewBox 0 0 150 150, 1unit=1px)内に<mask>を注入し、全描画要素に適用する。
    applyNfcMask(tries = 0) {
      const svg = this.$refs.qrCode && this.$refs.qrCode.querySelector('svg');
      if (!svg) {
        if (tries < 60) requestAnimationFrame(() => this.applyNfcMask(tries + 1));
        return;
      }
      if (svg.querySelector('#nfc-cut')) return; // 二重適用防止

      const NS = 'http://www.w3.org/2000/svg';
      // QR全体をCSSでQR_SCALE倍するため、くり抜きはローカルで1/QR_SCALEし、
      // 表示後の物理サイズがプレートのくり抜き(NFC_W×NFC_H mm)と一致するようにする。
      const W = NFC_W * U / QR_SCALE;   // NFC枠 横(mm)
      const H = NFC_H * U / QR_SCALE;   // NFC枠 縦(mm)
      const R = NFC_R * U / QR_SCALE;   // 角丸(mm)
      const cx = 75;       // viewBox中央
      const cy = 75;

      const el = (tag, attrs) => {
        const n = document.createElementNS(NS, tag);
        for (const k in attrs) n.setAttribute(k, attrs[k]);
        return n;
      };

      const mask = el('mask', {
        id: 'nfc-cut',
        maskUnits: 'userSpaceOnUse',
        x: 0, y: 0, width: 150, height: 150,
      });
      // 白=残す / 黒=くり抜く
      mask.appendChild(el('rect', { x: 0, y: 0, width: 150, height: 150, fill: 'white' }));
      mask.appendChild(el('rect', {
        x: cx - W / 2, y: cy - H / 2, width: W, height: H, rx: R, ry: R, fill: 'black',
        // QRローカルで+45°回すと、ページ上では直立のNFC枠に一致する
        transform: `rotate(45 ${cx} ${cy})`,
      }));

      let defs = svg.querySelector('defs');
      if (!defs) {
        defs = el('defs', {});
        svg.insertBefore(defs, svg.firstChild);
      }
      defs.appendChild(mask);

      // defs以外の描画要素(ドット/コーナー)をマスク付きグループに包む
      const g = el('g', { mask: 'url(#nfc-cut)' });
      [...svg.childNodes].forEach((n) => {
        if (n !== defs && n.nodeType === 1) g.appendChild(n);
      });
      svg.appendChild(g);
    },
  },
};
</script>

<style lang="scss">
#qr {
  circle {
    r: 1.5;
  }
  rect:first-child {
    rx: 18;
  }
}
</style>

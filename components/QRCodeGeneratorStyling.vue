<template>
  <div class="relative w-fit">
    <div class="absolute inset-0 flex justify-center items-center opacity-60">
      <div class="absolute inset-0 flex justify-center items-center">
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
    <div class="absolute inset-0 flex justify-center items-center zen-maru-gothic-medium text-lg text-center text-[#013] opacity-60 translate-y-[20.7mm] scale-50">
      {{ data }}
    </div>
  </div>
</template>

<script>
import QRCodeStyling from "qr-code-styling";

export default {
  props: {
    data: { type: String, required: true },
  },
  mounted() {
    const qrCode = new QRCodeStyling({
      width: 150,
      height: 150,
      type: 'svg',
      data: this.data,
      dotsOptions: { color: '#013', type: 'dots' },
      cornersSquareOptions: { color: '#013', type: 'extra-rounded' },
      backgroundOptions: { color: '#FFF4' },
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
      const U = 96 / 25.4; // 1mm をpx(=viewBox unit)へ。96dpi基準
      const W = 9 * U;     // NFC枠 横9mm
      const H = 19 * U;    // NFC枠 縦19mm
      const R = 1 * U;     // 角丸1mm
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

      // defs以外の描画要素をマスク付きグループに包む
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

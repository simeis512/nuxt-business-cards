<template>
  <div class="relative w-fit">
    <!-- opacity-60 はグループ不透明度＝PDFで分離透明グループになり、GIMP(poppler)が
         黒背景に合成して暗転する。各色のアルファに焼き込んで分離グループを避ける。 -->
    <div class="absolute inset-0 flex justify-center items-center">
      <div class="absolute inset-0 flex justify-center items-center">
        <div ref="qrCode" id="qr" class="-rotate-90" />
      </div>
      <div class="absolute inset-0 flex justify-center items-center">
        <div class="absolute flex justify-center items-center w-[9mm] h-[19mm] rounded-[1mm] bg-transparent -rotate-45">
          <div class="absolute left-[1.5mm] top-[1.2mm] scale-[.8]">
          <!-- https://iconduck.com/icons/90434/nfc-variant-off -->
            <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
              <path
                d="m1.25 2.05 20.7 20.7-1.25 1.25-2-2h-14.7a2 2 0 0 1 -2-2v-14.7l-2-2zm2.56-.05h.19 16c1.11 0 2 .89 2 2v16 .19l-2-1.99v-14.2h-14.2zm2.19 7.3-2-2v12.7h12.7l-2-2h-8.7zm12 6.9-2-2v-6.2h-3v2.28c.6.34 1 .98 1 1.72v.19l-3-2.99v-1.2a2 2 0 0 1 2-2h5zm-10-.2h4.7l-4.7-4.7zm2-8h-.2l-2-2h2.2z"
                fill="#00113366"
              />
            </svg>
          </div>
        </div>
      </div>
    </div>
    <div class="absolute inset-0 flex justify-center items-center zen-maru-gothic-medium text-lg text-center text-[#00113399] translate-y-[20.7mm] scale-50">
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
      // 旧: 色は#013/#FFF4＋ラッパのopacity-60。PDF対策でopacityを廃し、
      // 60%を各色のアルファに焼き込む（#013@60%=#00113399, #FFF4@60%≒#FFFFFF29）。
      dotsOptions: { color: '#00113399', type: 'dots' },
      cornersSquareOptions: { color: '#00113399', type: 'extra-rounded' },
      backgroundOptions: { color: '#FFFFFF29' },
      qrOptions: { errorCorrectionLevel: 'H' },
    });
    qrCode.append(this.$refs.qrCode);
    this.applyNfcCut();
  },
  methods: {
    // 中央のNFC貼り付け枠（9mm×19mm 角丸1mm）の形にQRをくり抜く。
    // mask/clipPath/group-opacity は ChromeのPDF保存→GIMP(poppler) で
    // 「分離透明グループが黒backdropに合成され暗転」する相互運用問題を起こす。
    // そこで透明グループを一切作らず、枠に重なるドット要素を物理削除して穴をあける。
    applyNfcCut(tries = 0) {
      const svg = this.$refs.qrCode && this.$refs.qrCode.querySelector('svg');
      if (!svg) {
        if (tries < 60) requestAnimationFrame(() => this.applyNfcCut(tries + 1));
        return;
      }
      if (svg.dataset.nfcCut) return; // 二重適用防止
      const circles = svg.querySelectorAll('circle');
      if (!circles.length) {
        if (tries < 60) requestAnimationFrame(() => this.applyNfcCut(tries + 1));
        return;
      }
      svg.dataset.nfcCut = '1';

      const U = 96 / 25.4; // 1mm をpx(=viewBox unit)へ。96dpi基準
      const hw = (9 * U) / 2;  // NFC枠 横9mm の半分
      const hh = (19 * U) / 2; // NFC枠 縦19mm の半分
      const R = 1 * U;         // 角丸1mm
      const cx = 75;           // viewBox中央
      const cy = 75;

      // 枠はQRローカルで+45°回転。点を-45°戻して軸並行の角丸矩形に入るか判定する。
      const c = Math.cos(-Math.PI / 4);
      const s = Math.sin(-Math.PI / 4);
      const inHole = (px, py) => {
        const dx = px - cx;
        const dy = py - cy;
        const ax = Math.abs(dx * c - dy * s);
        const ay = Math.abs(dx * s + dy * c);
        if (ax > hw || ay > hh) return false;
        if (ax <= hw - R || ay <= hh - R) return true; // 直線部
        const ex = ax - (hw - R);                       // 角丸部
        const ey = ay - (hh - R);
        return ex * ex + ey * ey <= R * R;
      };

      circles.forEach((d) => {
        const px = parseFloat(d.getAttribute('cx'));
        const py = parseFloat(d.getAttribute('cy'));
        if (Number.isFinite(px) && Number.isFinite(py) && inHole(px, py)) d.remove();
      });
    },
  },
};
</script>

<style lang="scss">
#qr {
  circle {
    r: 1.3;
  }
  rect:first-child {
    rx: 18;
  }
}
</style>

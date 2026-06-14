<template>
  <div data-card class="w-[91mm] h-[55mm] p-2 relative bg-[#FFF0] overflow-hidden">
    <div class="absolute inset-0 flex justify-center items-center -left-[36mm]">
      <QRCodeGeneratorStyling v-if="qrData" :data="qrData" class="rotate-45" />
    </div>
    <!-- data-glass-plate: 背景canvas側がこの矩形と形状(path/viewBox)を実測して、内側にだけ背景をぼかして焼き込む -->
    <div
      data-glass-plate
      data-plate-role="text"
      data-plate-path="M 12 4 A 20 8 20 0 0 4 12 L 72 80 A 24 24 90 0 0 88 88 H 192 A 20 8 20 0 0 200 80 L 132 12 A 24 24 90 0 0 116 4 Z"
      data-plate-vb="205 90"
      class="absolute top-[3mm] left-[35mm]"
    >
      <svg width="205" height="90" viewBox="0 0 205 90" xmlns="http://www.w3.org/2000/svg">
        <path
          d="M 12 4 A 20 8 20 0 0 4 12 L 72 80 A 24 24 90 0 0 88 88 H 192 A 20 8 20 0 0 200 80 L 132 12 A 24 24 90 0 0 116 4 Z"
          fill="#FFF0"
          stroke="#0135"
          stroke-width="0.2"
        />
      </svg>
      <div class="absolute inset-0 flex flex-col justify-center items-center opacity-70">
        <div class="absolute top-[1.2mm] -left-[4.5mm] zen-maru-gothic-medium text-[#0139] text-[0.8em] -tracking-[.04em] leading-[0.9em] scale-[.65]">
          <div v-for="(l, index) in JSON.parse(job)" :key="l" :style="{ 'margin-left': `${index * 8}em` }">
            {{ l }}
          </div>
        </div>
        <div class="absolute top-[6.2mm] left-[16.5mm] zen-maru-gothic-bold text-[#0138] text-[2em] -tracking-[.02em] [-webkit-text-stroke:0.6px_#013A] [text-shadow:1px_1px_1px_#0137]">{{ name }}</div>
        <div class="absolute top-[18.5mm] left-[36.5mm] zen-maru-gothic-medium text-[#0139] text-[0.7em] -tracking-[.04em]">{{ account }}</div>
      </div>
    </div>
    <div
      data-glass-plate
      data-plate-role="image"
      data-plate-path="M 12 88 A 20 8 -20 0 1 4 80 L 72 12 A 24 24 90 0 1 88 4 H 192 A 20 8 -20 0 1 200 12 L 132 80 A 24 24 90 0 1 116 88 Z"
      data-plate-vb="205 90"
      class="absolute top-[27.7mm] left-[35mm]"
    >
      <svg width="205" height="90" viewBox="0 0 205 90" xmlns="http://www.w3.org/2000/svg">
        <path
          d="M 12 88 A 20 8 -20 0 1 4 80 L 72 12 A 24 24 90 0 1 88 4 H 192 A 20 8 -20 0 1 200 12 L 132 80 A 24 24 90 0 1 116 88 Z"
          fill="#FFF0"
          stroke="#0135"
          stroke-width="0.2"
        />
        <clipPath id="clip-shape">
          <path
            d="M 12 88 A 20 7 -18 0 1 4 80 L 72 12 A 24 24 90 0 1 88 4 H 192 A 20 7 -18 0 1 200 12 L 132 80 A 24 24 90 0 1 116 88 Z"
            fill="#FFF5"
            stroke="#0135"
            stroke-width="0.2"
            class="origin-center scale-[.96]"
          />
        </clipPath>
        <image x="4" y="2" width="198" height="88" opacity="0.85" clip-path="url(#clip-shape)" :xlink:href="`data:image/png;base64,${img}`" />
      </svg>
      <div class="absolute top-[18.7mm] left-[2.2mm] zen-maru-gothic-bold text-[#FFFF] text-[0.7em] -tracking-[.1em] scale-95" style="-webkit-text-stroke: 0.5px #013A;">{{ alt }}</div>
    </div>
  </div>
</template>

<script>
import QRCodeGeneratorStyling from './QRCodeGeneratorStyling.vue';

export default {
  props: {
    name: { type: String, default: '' },
    account: { type: String, default: '' },
    job: { type: String, default: '' },
    qrData: { type: String, default:'' },
    img: { type: String, default: '' },
    alt: { type: String, default: '' },
  },
  components: { QRCodeGeneratorStyling },
};
</script>

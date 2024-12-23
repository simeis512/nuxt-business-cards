<template>
  <div class="w-[91mm] h-[55mm] p-2 relative bg-[#FFF0] overflow-hidden">
    <div class="absolute inset-0 flex justify-center items-center -left-[36mm]">
      <QRCodeGeneratorStyling v-if="qrData" :data="qrData" class="rotate-45" />
    </div>
    <div class="absolute top-[3mm] left-[35mm]">
      <svg width="205" height="90" viewBox="0 0 205 90" xmlns="http://www.w3.org/2000/svg">
        <path
          d="M 12 4 A 20 8 20 0 0 4 12 L 72 80 A 24 24 90 0 0 88 88 H 192 A 20 8 20 0 0 200 80 L 132 12 A 24 24 90 0 0 116 4 Z"
          fill="#FFF3"
          stroke="#013A"
          stroke-width="0.2"
        />
      </svg>
      <div class="absolute inset-0 flex flex-col justify-center items-center opacity-70">
        <div class="absolute top-[1.2mm] -left-[4.5mm] zen-maru-gothic-medium text-[#013B] text-[0.8em] -tracking-[.1em] leading-[0.9em] scale-[.65]">
          <div v-for="(l, index) in JSON.parse(job)" :key="l" :style="{ 'margin-left': `${index * 8}em` }">
            {{ l }}
          </div>
        </div>
        <div class="absolute top-[6.2mm] left-[16.7mm] zen-maru-gothic-bold text-[#013E] text-[2em] -tracking-[.1em]">{{ name }}</div>
        <div class="absolute top-[18.5mm] left-[38mm] zen-maru-gothic-medium text-[#013B] text-[0.7em] -tracking-[.1em]">{{ account }}</div>
      </div>
    </div>
    <div class="absolute top-[27.7mm] left-[35mm]">
      <svg width="205" height="90" viewBox="0 0 205 90" xmlns="http://www.w3.org/2000/svg">
        <path
          d="M 12 88 A 20 8 -20 0 1 4 80 L 72 12 A 24 24 90 0 1 88 4 H 192 A 20 8 -20 0 1 200 12 L 132 80 A 24 24 90 0 1 116 88 Z"
          fill="#FFF5"
          stroke="#013A"
          stroke-width="0.2"
        />
        <clipPath id="clip-shape">
          <path
            d="M 12 88 A 20 7 -18 0 1 4 80 L 72 12 A 24 24 90 0 1 88 4 H 192 A 20 7 -18 0 1 200 12 L 132 80 A 24 24 90 0 1 116 88 Z"
            fill="#FFF5"
            stroke="#013A"
            stroke-width="0.2"
            class="origin-center scale-[.96]"
          />
        </clipPath>
        <image x="4" y="2" width="198" height="88" clip-path="url(#clip-shape)" :xlink:href="`data:image/png;base64,${img}`" />
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

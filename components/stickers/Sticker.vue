<template>
  <div class="w-[33mm] h-[33.9mm] p-2 relative bg-[#FFF0] overflow-hidden">
    <div class="absolute inset-0 flex justify-center items-center">
      <QRCodeGeneratorStylingStickers v-if="qrData" :data="qrData" class="" />
    </div>
  </div>
</template>

<script>
import QRCodeGeneratorStylingStickers from './QRCodeGeneratorStylingStickers.vue';

export default {
  props: {
    name: { type: String, default: '' },
    account: { type: String, default: '' },
    job: { type: String, default: '' },
    qrData: { type: String, default:'' },
    img: { type: String, default: '' },
    alt: { type: String, default: '' },
  },
  components: { QRCodeGeneratorStylingStickers },
};
</script>

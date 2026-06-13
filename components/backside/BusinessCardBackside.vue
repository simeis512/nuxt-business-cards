<template>
  <div class="w-[91mm] h-[55mm] p-2 relative bg-[#FFF0] overflow-hidden">
    <div class="absolute inset-0 flex justify-center items-center">
      <QRCodeGeneratorStylingBackside v-if="qrData" :data="qrData" class="" />
    </div>
  </div>
</template>

<script>
import QRCodeGeneratorStylingBackside from './QRCodeGeneratorStylingBackside.vue';

export default {
  props: {
    name: { type: String, default: '' },
    account: { type: String, default: '' },
    job: { type: String, default: '' },
    qrData: { type: String, default:'' },
    img: { type: String, default: '' },
    alt: { type: String, default: '' },
  },
  components: { QRCodeGeneratorStylingBackside },
};
</script>

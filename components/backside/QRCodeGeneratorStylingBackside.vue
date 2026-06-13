<template>
  <div class="relative w-fit">
    <div class="absolute inset-0 flex justify-center items-center opacity-60">
      <div class="absolute inset-0 flex justify-center items-center">
        <div ref="qrCode" id="qr" class="" />
      </div>
    </div>
    <div class="absolute inset-0 flex justify-center items-center zen-maru-gothic-medium text-lg text-center text-[#013] opacity-60 translate-y-[16mm] scale-50">
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
      width: 120,
      height: 120,
      type: 'svg',
      data: this.data,
      dotsOptions: { color: '#013', type: 'rounded' },
      cornersSquareOptions: { color: '#013', type: 'extra-rounded' },
      backgroundOptions: { color: '#FFF8' },
      qrOptions: { errorCorrectionLevel: 'M' },
    });
    qrCode.append(this.$refs.qrCode);
  },
};
</script>

<style lang="scss">
#qr {
  circle {
    r: 2;
  }
  rect:first-child {
    rx: 18;
  }
}
</style>

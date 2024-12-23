<template>
  <div class="relative w-fit">
    <div class="absolute inset-0 flex justify-center items-center opacity-50">
      <div class="absolute inset-0 flex justify-center items-center">
        <div ref="qrCode" id="qr" class="-rotate-90" />
      </div>
      <div class="absolute inset-0 flex justify-center items-center">
        <div class="absolute inline-block w-[9mm] h-[19mm] rounded-[1mm] bg-white -rotate-45" />
      </div>
    </div>
    <div class="absolute inset-0 flex justify-center items-center text-[0.5em] text-center opacity-50 translate-y-[20.5mm]">{{ data }}</div>
  </div>
</template>

<script>
import QRCode from "easyqrcodejs";

export default {
  props: {
    data: { type: String, required: true },
  },
  mounted() {
    const options = {
      text: this.data,
      width: 140,
      height: 140,
      colorDark: "#000",
      colorLight: "#FFF0",
      correctLevel: QRCode.CorrectLevel.H,
      dotScale: 0.4,
      dotScaleTiming: 0.4,
      dotScaleA: 0.4,
      quietZone: 2,
      drawer: 'svg',
    };

    // QRコードを描画
    new QRCode(this.$refs.qrCode, options);
  },
};
</script>

<style lang="scss">
#qr rect {
  rx: 50%;
  ry: 50%;
}
</style>

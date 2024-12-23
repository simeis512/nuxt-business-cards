<template>
  <div class="relative w-fit">
    <div class="absolute inset-0 flex justify-center items-center opacity-60">
      <div class="absolute inset-0 flex justify-center items-center">
        <div ref="qrCode" id="qr" class="-rotate-90" />
      </div>
      <div class="absolute inset-0 flex justify-center items-center">
        <div class="absolute flex justify-center items-center w-[9mm] h-[19mm] rounded-[1mm] bg-white -rotate-45">
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
      backgroundOptions: { color: '#FFF8' },
      qrOptions: { errorCorrectionLevel: 'H' },
    });
    qrCode.append(this.$refs.qrCode);
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

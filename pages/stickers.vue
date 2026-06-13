<template>
  <div class="print-page">
    <CardGridStickers />
  </div>
</template>

<script>
import CardGridStickers from "@/components/stickers/CardGridStickers.vue";

export default {
  components: { CardGridStickers },
};
</script>

<style lang="scss">
@media print {
  @page {
    size: A4;
    margin: 0;
  }
  body {
    margin: 0;
    padding: 0;
    background: green;
  }
  .print-page {
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }
}
</style>

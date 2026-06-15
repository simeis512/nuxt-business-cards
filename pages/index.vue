<template>
  <div class="print-page">
    <BackgroundLayout />
    <CardGrid />
  </div>
</template>

<script>
import BackgroundLayout from "@/components/BackgroundLayout.vue";
import CardGrid from "@/components/CardGrid.vue";

export default {
  components: { BackgroundLayout, CardGrid },
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
    background: #fff; /* 用紙の地色。canvasがA4全面を覆うが、端のはみ被り防止に白 */
  }
  .print-page {
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }
}
</style>

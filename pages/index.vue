<template>
  <div class="print-page">
    <CardGrid />
  </div>
</template>

<script>
import CardGrid from "@/components/CardGrid.vue";

export default {
  components: { CardGrid },
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

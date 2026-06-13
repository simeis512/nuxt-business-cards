<template>
  <div class="print-page">
    <CardGridBackside />
  </div>
</template>

<script>
import CardGridBackside from "@/components/backside/CardGridBackside.vue";

export default {
  components: { CardGridBackside },
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

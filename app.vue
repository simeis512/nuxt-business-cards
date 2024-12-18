<template>
  <div class="relative w-full h-full">
    <!-- 共通背景 -->
    <BackgroundLayout />

    <!-- ページコンテンツ -->
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </div>
</template>

<script setup>
import BackgroundLayout from "@/components/BackgroundLayout.vue";
</script>

<style lang="scss">
html, body {
  margin: 0;
  padding: 0;
  font-family: 'Inter', sans-serif;
  background-color: #f9fafb; /* Tailwindのbg-gray-100相当 */
}
</style>

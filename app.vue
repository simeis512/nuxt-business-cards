<template>
  <div class="relative w-full h-full">
    <!-- ページコンテンツ -->
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </div>
</template>

<style lang="scss">
html, body {
  margin: 0;
  padding: 0;
  font-family: 'Inter', sans-serif;
  background-color: #f9fafb; /* Tailwindのbg-gray-100相当 */
}
</style>

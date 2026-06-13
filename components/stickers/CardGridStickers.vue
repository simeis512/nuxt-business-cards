<template>
  <div class="absolute top-0 left-0 w-[210mm] h-[297mm] px-[6mm] py-[12.9mm] grid grid-cols-6 gap-x-[0mm] gap-y-[0mm]">
    <Sticker
      v-for="(card, index) in cards"
      :key="index"
      :name="card.name"
      :account="card.account"
      :job="card.job"
      :qrData="card.qrData"
      :img="card.img"
      :alt="card.alt"
    />
  </div>
</template>

<script>
import Sticker from './Sticker.vue';
import { fetchGeneratedImage } from '~/api/stableDiffusion';
import image from '~/assets/images/image.png';

const { public: { prompt, batchCount, sdModel, name, account, job, qrData } } = useRuntimeConfig();

export default {
  components: { Sticker },
  data() {
    return {
      cards: Array.from({ length: 48 }, () => ({
        name,
        account,
        job,
        qrData,
        img: '',
        alt: '',
      })),
    };
  },
  methods: {
    async generateImages() {
      console.log(prompt, batchCount, sdModel, name, account, job, qrData)
      const generatedImages = await fetchGeneratedImage(prompt, 900, 400, batchCount);
      generatedImages.forEach((img, i) => {
        this.cards[i].img = img;
        this.cards[i].alt = sdModel;
      });
    },
    async fetchBase64Image(imageUrl) {
      // Fetch画像データを取得してBase64形式に変換
      const response = await fetch(imageUrl);
      const blob = await response.blob();

      return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onloadend = () => resolve(reader.result.split(',')[1]); // Base64データ部分だけを取得
        reader.onerror = reject;
        reader.readAsDataURL(blob);
      });
    }
  },
  mounted: async function () {
    const img = await this.fetchBase64Image(image);
    this.cards.forEach((card) => card.img = img);

    this.generateImages();
  }
};
</script>

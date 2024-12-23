// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2024-11-01',
  devtools: { enabled: true },
  devServer: {
    host: '0.0.0.0',
    port: 3000,
  },
  ssr: false,
  css: [
    '~/assets/styles/main.scss',
    '~/assets/styles/google-fonts.scss',
  ],
  postcss: {
    plugins: {
      tailwindcss: {},
      autoprefixer: {},
    },
  },
  plugins: [
    { src: '~/plugins/p5.client.js' },
  ],
  vite: {
    css: {
      preprocessorOptions: {
        scss: {
          api: "modern-compiler",
        },
      },
    },
  },
  app: {
    head: {
      link: [
        {
          rel: 'preconnect',
          href: 'https://fonts.googleapis.com',
        },
        {
          rel: 'preconnect',
          href: 'https://fonts.gstatic.com',
          crossorigin: '',
        },
        {
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Zen+Maru+Gothic:wght@400;500;700&display=swap',
        },
      ],
    },
  },
  runtimeConfig: {
    public: {
      sdApiUrl: process.env.SD_API_URL || 'http://localhost:7860',
      prompt: process.env.SD_PROMPT || '1girl',
      batchCount: process.env.BATCH_COUNT || '10',
      sdModel: process.env.SD_MODEL || 'Dymmy model',
      name: process.env.NAME || 'Dummy',
      account: process.env.ACCOUNT || '@dummy',
      job: process.env.JOB || 'Dummy job',
      qrData: process.env.QR_DATA || 'https://dummy.com',
    },
  },
})

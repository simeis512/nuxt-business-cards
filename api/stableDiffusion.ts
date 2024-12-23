import axios from 'axios';

export const fetchGeneratedImage = async (prompt: string, w=512, h=512, batch=10) => {
  const { public: { sdApiUrl } } = useRuntimeConfig();
  try {
    const response = await axios.post(`${sdApiUrl}/sdapi/v1/txt2img`, {
      prompt: `masterpiece, best quality, ${prompt}`,
      negative_prompt: 'EasyNegative, extra fingers, fewer fingers, lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts,signature, watermark, username, blurry, artist name,',
      steps: 30,
      width: w/2,
      height: h/2,
      batch_size: batch,
      sampler_index: 'Euler a',
      enable_hr: true,
      hr_upscaler: '4x-AnimeSharp',
      hr_second_pass_steps: 15,
      hr_resize_x: w,
      hr_resize_y: h,
      denoising_strength: 0.5,
      hr_scale: 2,
      hr_sampler: 'DPM++ 2M',
    });

    // Base64画像データを返す
    return response.data.images;
  } catch (error) {
    console.error('Error generating image:', error);
    throw error;
  }
};

<script>
import Chip from 'primevue/chip'
import { toRaw } from 'vue';
export default {
  //inheritAttrs: false, // ??
  props: {
    color: {
      type: String,
      required: true
    }
  },
  setup({ color }) {
    const hexToYIQ = (hexColor) => {
      // Convert hex to RGB
      // Quick and dirty without validation
      const [r, g, b] = hexColor.match(/.{2}/g).map(val => parseInt(val, 16))
      // Convert RGB to YIQ
      return ((r * 299) + (g * 587) + (b * 114)) / 1000
    }
    // Configurable threshold?
    const threshold = 128
    const textColor = hexToYIQ(toRaw(color)) >= threshold ? 'dark-text' : 'bright-text'
    return {
      textColor
    }
  },
  components: {
    Chip
  }
}
</script>
<template>
  <Chip :style="{ 'background-color': '#' + color }">
    <span :class="textColor"><slot></slot></span>
  </Chip>
</template>
<style lang="scss" scoped>
.p-chip .dark-text {
  color: #000;
}
.p-chip .bright-text {
  color: #fff;
}
</style>

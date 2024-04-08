<script>
import Chip from '@/components/Chip.vue'
import useTextClassForBackground from '@/components/UseTextClassForBackground.js' //BackgroundColor?
export default {
  props: {
    color: {
      type: String,
      required: true
    }
  },
  setup({ color }) {
    const textColorClass = useTextClassForBackground(color, 'text-black', 'text-white')
    return {
      color,
      textColorClass
    }
  },
  components: {
    Chip
  }
}
</script>
<template>
  <Chip
    :class="textColorClass"
    :style="{ 'background-color': '#' + color }"
  >
    <template v-for="(_, name) in $slots" v-slot:[name]="slotProps">
      <slot v-if="slotProps" :name="name" v-bind="slotProps" />
      <slot v-else :name="name" />
    </template>
  </Chip>
</template>
<style lang="scss">
.p-chip {
  .dark-text {
    color: #000;
  }
  .bright-text {
    color: #fff;
  }
}
</style>

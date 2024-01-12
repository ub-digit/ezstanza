<script>
import { ref, toRef, computed } from 'vue'
import OverlayPanel from 'primevue/overlaypanel';
export default {
  props: {
    text: {
      type: String,
      required: true
    }
  },
  setup( props ) {
    const tooltip = ref(null)
    const toggleTooltip = (event) => {
      tooltip.value.toggle(event)
    }
    const tooltipText = toRef(props, 'text')
    return {
      tooltip,
      tooltipText,
      toggleTooltip
    }
  },
  components: {
    OverlayPanel
  }

}
</script>
<template>
  <slot :mouseover="toggleTooltip" :mouseleave="toggleTooltip"></slot>
  <OverlayPanel :pt="{ content: { class: 'overlay-tooltip' } }" ref="tooltip">
    <span class="text-sm">{{ tooltipText }}</span>
  </OverlayPanel>
</template>
<style>
.p-overlaypanel .p-overlaypanel-content.overlay-tooltip {
  padding: .5rem .9rem;
}
</style>

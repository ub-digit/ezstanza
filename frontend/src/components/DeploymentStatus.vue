<script>
import { ref, computed } from 'vue'
import OverlayPanel from 'primevue/overlaypanel';
export default {
  props: {
    status: {
      type: String,
      required: true
    }
  },
  setup({ status }) {
    const tooltip = ref(null)
    const toggleTooltip = (event) => {
      tooltip.value.toggle(event)
    }
    const tooltipText = computed(() => {
      //TODO: i18n
      console.dir(status)
      const textMapping = {
        pending: 'Pending',
        deploying: 'Deploying',
        completed: 'Completed',
        failed: 'Failed'
      }
      return textMapping[status];
    })
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
  <span :class="['deployment-status', status]" @mouseover="toggleTooltip" @mouseleave="toggleTooltip"/>
  <!-- <span :class="['deployment-status', status]" @click="toggleTooltip"/> -->
  <OverlayPanel :pt="{ content: { class: 'deployment-status-tooltip' } }" ref="tooltip">
    <span class="text-sm">{{ tooltipText }}</span>
  </OverlayPanel>
</template>
<style>
.deployment-status {
  display: inline-block;
  width: 1rem;
  min-width: 1rem;
  height: 1rem;
  border-radius: 50%;
  padding: 0;
}

.deployment-status.pending {
  background-color: var(--gray-500);
}
.deployment-status.deploying {
  background-color: var(--teal-500);
}
.deployment-status.completed {
  background-color: var(--green-500);
}
.deployment-status.failed {
  background-color: var(--red-500);
}
.p-overlaypanel .p-overlaypanel-content.deployment-status-tooltip {
  padding: .5rem .9rem;
}
</style>

<script>
import { ref, toRef, computed } from 'vue'
import Tooltip from '@/components/Tooltip.vue';
export default {
  props: {
    status: {
      type: String,
      required: true
    }
  },
  setup( props ) {
    const status = toRef(props, 'status')
    const tooltipText = computed(() => {
      //TODO: i18n
      const textMapping = {
        pending: 'Pending',
        deploying: 'Deploying',
        completed: 'Completed',
        failed: 'Failed'
      }
      return textMapping[status.value];
    })
    return {
      tooltipText
    }
  },
  components: {
    Tooltip
  }
}
</script>
<template>
  <Tooltip :text="tooltipText" v-slot="events">
    <span :class="['deployment-status', status]" v-on="events"/>
  </Tooltip>
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
</style>

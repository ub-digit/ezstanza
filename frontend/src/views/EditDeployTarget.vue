<script>
import { watch, ref, inject } from 'vue'
import { useRoute } from 'vue-router'
import useOnSubmit from '@/components/UseOnEntityFormSubmit.js'
import DeployTargetForm from '@/components/DeployTargetForm.vue'

export default {
  setup() {
    const route = useRoute()
    const deployTarget = ref()
    const onSubmit = useOnSubmit('deploy_target', 'deploy_targets', 'update')
    const api = inject('api')

    // Replace with watchEffect?
    watch(
      () => route.params.id,
      async newId => {
        // Triggered when leaving route, WTF!?!?
        if (typeof newId !== 'undefined') {
          //TODO: error handling
          const result = await api.deploy_targets.fetch(newId)
          deployTarget.value = result.data
        }
      },
      { immediate: true }
    )

    return {
      deployTarget,
      onSubmit
    }
  },
  components: {
    DeployTargetForm
  }
}
</script>
<template>
  <DeployTargetForm v-if="deployTarget" :deployTarget="deployTarget" @submit="onSubmit"/>
</template>

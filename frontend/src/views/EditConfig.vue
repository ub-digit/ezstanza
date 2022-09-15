<script>
import { useRoute } from 'vue-router'
import { watch, ref, inject } from 'vue'
import useOnSubmit from '@/components/UseOnEntityFormSubmit.js'
import ConfigForm from '@/components/ConfigForm.vue'

export default {
  setup() {
    const route = useRoute()
    const config = ref()
    const onSubmit = useOnSubmit('configs', 'config', 'update')
    const api = inject('api')

    // Replace with watchEffect?
    watch(
      () => route.params.id,
      async newId => {
        // Triggered when leaving route, WTF!?!?
        if (typeof newId !== 'undefined') {
          //TODO: error handling
          const result = await api.configs.fetch(newId)
          config.value = result.data
        }
      },
      { immediate: true }
    )

    return {
      config,
      onSubmit
    }
  },
  components: {
    ConfigForm
  }
}
</script>
<template>
  <ConfigForm v-if="config" :config="config"  @submit="onSubmit"/>
</template>

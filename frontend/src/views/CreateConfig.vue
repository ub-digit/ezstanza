<script>
import { ref } from 'vue'
import ConfigForm from '@/components/ConfigForm.vue'
import useOnSubmit from '@/components/UseOnEntityFormSubmit.js'

export default {
  setup() {
    const config = ref({
      stanza_revisions: []
    })
    const onSubmit = useOnSubmit('config', 'configs', 'create')

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
  <ConfigForm :config="config" @submit="onSubmit"/>
</template>

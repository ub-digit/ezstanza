<script>
import { ref } from 'vue'
import StanzaForm from '@/components/StanzaForm.vue'
import useOnSubmit from '@/components/UseOnEntityFormSubmit.js'

export default {
  setup() {
    const stanza = ref({
      current_deployments: []
    })
    const onSubmit = useOnSubmit('stanza', 'stanzas', 'create')

    return {
      stanza,
      onSubmit
    }
  },
  components: {
    StanzaForm
  }
}
</script>
<template>
  <StanzaForm :stanza="stanza" @submit="onSubmit"/>
</template>

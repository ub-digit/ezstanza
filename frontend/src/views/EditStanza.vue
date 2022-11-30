<script>
import { watch, ref, inject } from 'vue'
import { useRoute } from 'vue-router'
import useOnSubmit from '@/components/UseOnEntityFormSubmit.js'
import StanzaForm from '@/components/StanzaForm.vue'

export default {
  setup() {
    const route = useRoute()
    const stanza = ref()
    const onSubmit = useOnSubmit('stanza', 'stanzas', 'update')
    const api = inject('api')

    // Replace with watchEffect?
    watch(
      () => route.params.id,
      async newId => {
        // Triggered when leaving route, WTF!?!?
        if (typeof newId !== 'undefined') {
          //TODO: error handling
          const result = await api.stanzas.fetch(newId)
          stanza.value = result.data
        }
      },
      { immediate: true }
    )

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
  <StanzaForm v-if="stanza" :stanza="stanza" @submit="onSubmit"/>
</template>

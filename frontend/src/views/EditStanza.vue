<script>
import { watch, inject, ref } from 'vue'
import { useRoute } from 'vue-router'
import StanzaForm from '@/components/StanzaForm.vue'

export default {
  setup() {
    const route = useRoute()
    const stanza = ref()
    const api = inject('api')
    // Replace with watchEffect?
    watch(
      () => route.params.id,
      async newId => {
        //TODO: error handling
        stanza.value = await api.stanzas.fetch(newId)
      },
      { immediate: true }
    )
    return {
      stanza
    }
  },
  components: {
    StanzaForm
  }
}
</script>
<template>
  <div v-if="stanza">
    <StanzaForm v-model="stanza"/>
  </div>
</template>

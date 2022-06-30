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
        const result = await api.stanzas.fetch(newId)
        stanza.value = result.data
      },
      { immediate: true }
    )

    function onSubmit(stanza, { setErrors }) {
      api.stanzas.update(stanza.id, { stanza: stanza })
        .catch((errors) => {
          console.log('errors')
          console.dir(errors)
          if (typeof errors === 'object') {
            console.log('setting errors')
            setErrors(errors)
          }
          else if(typeof errors == 'string') {
            //TODO: toast error
            alert(errors)
          }
        })
    }
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
  <div v-if="stanza">
    <StanzaForm :stanza="stanza" @submit="onSubmit"/>
  </div>
</template>

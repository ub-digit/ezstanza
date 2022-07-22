<script>
import { watch, inject, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import StanzaForm from '@/components/StanzaForm.vue'
import { useToast } from 'primevue/usetoast'
import { ToastSeverity } from 'primevue/api'

export default {
  setup() {
    const route = useRoute()
    const router = useRouter()
    const stanza = ref()
    const api = inject('api')
    const toast = useToast()

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


    function onSubmit(stanza, { setErrors }) {
      api.stanzas.update(stanza.id, { stanza: stanza })
        .then((result) => {
          toast.add({
            severity: ToastSeverity.SUCCESS,
            summary: 'Stanza created',
            detail: `Stanza "${result.data.name}" successfully updated`,
            life: 3000
          })
          if ('destination' in route.query) {
            router.push(route.query.destination)
          }
        }).catch((errors) => {
          if (typeof errors === 'object') {
            setErrors(errors)
          }
          else if(typeof errors == 'string') {
            toast.add({
              severity: ToastSeverity.ERROR,
              summary: 'Stanza creation failed',
              detail: `An error occured updating stanza: "${errors}"`,
              life: 3000
            })
          }
          else {
            toast.add({
              severity: ToastSeverity.ERROR,
              summary: 'Stanza creation failed',
              detail: 'An error occured updating stanza',
              life: 3000
            })
            console.dir(errors)
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

<script>
import { watch, inject, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import StanzaForm from '@/components/StanzaForm.vue'
import { useToast } from 'primevue/usetoast'
import { ToastSeverity } from 'primevue/api'

export default {
  setup() {
    const stanza = ref({})
    const api = inject('api')
    const toast = useToast()
    const route = useRoute()
    const router = useRouter()

    function onSubmit(stanza, { setErrors, resetForm }) {
      api.stanzas.create({ stanza: stanza })
        .then((result) => {
          toast.add({
            severity: ToastSeverity.SUCCESS,
            summary: 'Stanza created',
            detail: `Stanza "${result.data.name}" successfully created`,
            life: 3000
          })
          resetForm()
          // @todo: featurize as composition api module
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

        }).catch((errors) => {
          if (typeof errors === 'object') {
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

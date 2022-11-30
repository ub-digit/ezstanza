import { inject } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { ToastSeverity } from 'primevue/api'
// TODO: Rename entityName => entityLabel etc
export default function useOnEntityFormSubmit(entityName, entityNamePluralized, op) {

  const api = inject('api')
  const toast = useToast()
  const route = useRoute()
  const router = useRouter()

  const entityLabelCapitalized = entityName.charAt(0).toUpperCase() + entityName.slice(1).replace('_', ' ')

  const opPastTense = {
    create: 'created',
    update: 'updated'
  }[op]
  const opPresentTense = {
    create: 'creating',
    update: 'updating'
  }[op]
  const opNoun = {
    create: 'creation',
    update: 'update'
  }[op]
  const toastTimeout = 3000

  return function(entity, { setErrors, resetForm }) {
    let args = op === 'update' ? [entity.id] : []
    args.push({ [entityName]: entity })

    api[entityNamePluralized][op](...args)
      .then((result) => {
        toast.add({
          severity: ToastSeverity.SUCCESS,
          summary: `${entityLabelCapitalized} ${opPastTense}`,
          detail: `${entityLabelCapitalized} "${result.data.name}" successfully ${opPastTense}`,
          life: toastTimeout
        })
        resetForm() //TODO: This should only be run on creation right??
        if ('destination' in route.query) {
          router.push(route.query.destination)
        }
      }).catch((error) => {
        // Unprocessable entity, validation errors
        if (error.response.status == 422) {
          setErrors(error.response.data.errors)
        }
        // Conflict
        else if (error.response.status == 409) {
          toast.add({
            severity: ToastSeverity.ERROR,
            summary: `${entityLabelCapitalized} ${opNoun} failed`,
            detail: `The ${entityName} has been modified by another user`,
            life: toastTimeout
          })
        }
        else if (
          typeof error.response.data === 'object' &&
          'errors' in error.response.data &&
          'detail' in error.response.data.errors
        ) {
          let detail = error.response.data.errors.detail
          toast.add({
            severity: ToastSeverity.ERROR,
            summary: `${entityLabelCapitalized} ${opNoun} failed`,
            detail: `An error occured ${opPresentTense} ${entityName}: "${detail}"`,
            life: toastTimeout
          })
        }
        else {
          toast.add({
            severity: ToastSeverity.ERROR,
            summary: `${entityLabelCapitalized} ${opNoun} failed`,
            detail: `An unknown error occured ${opPresentTense} ${entityName}: "${error.message}"`,
            life: toastTimeout
          })
        }
      })
  }
}

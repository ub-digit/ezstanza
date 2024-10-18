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
  const toastTimeout = 5000

  return function(entity, { setErrors, resetForm }, options = {}) {
    let args = op === 'update' ? [entity.id] : []
    args.push(entity)

    return api[entityNamePluralized][op](...args)
      .then((result) => {
        let detail = result.data.name ?
          `${entityLabelCapitalized} "${result.data.name}" successfully ${opPastTense}` :
          `${entityLabelCapitalized} successfully ${opPastTense}`
        toast.add({
          severity: ToastSeverity.SUCCESS,
          summary: `${entityLabelCapitalized} ${opPastTense}`,
          detail: detail,
          life: toastTimeout
        })

        // @TODO: this is horrible, should instead propagate data through event
        // in component for two way binding, but lots of issues with that as well,
        // not even sure possible witout using watchers and probably lots of other
        // hacks
        if (op === 'update') {
          const formState = {
            values: {
              ...result.data,
              deploy_to_deploy_targets: []
            }
          }
          resetForm(formState)
        }
        else {
          resetForm()
        }

        const destination = options.destination || route.query.destination
        if (destination) {
          router.push(destination)
        }
        return result.data
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

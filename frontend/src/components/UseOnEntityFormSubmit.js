import { inject } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { ToastSeverity } from 'primevue/api'

export default function useOnEntityFormSubmit(resource, entityName, op) {

  const api = inject('api')
  const toast = useToast()
  const route = useRoute()
  const router = useRouter()

  const entityNameCapitalized = entityName.charAt(0).toUpperCase() + entityName.slice(1)
  const opPastTense = {
    create: 'created',
    update: 'updated'
  }[op]
  const opPresentTense = {
    create: 'creating',
    update: 'updateing'
  }[op]
  const opNoun = {
    create: 'creation',
    update: 'update'
  }[op]
  const toastTimeout = 3000

  return function(entity, { setErrors, resetForm }) {
    let args = op === 'update' ? [entity.id] : []
    args.push({ [entityName]: entity })

    api[resource][op](...args)
      .then((result) => {
        toast.add({
          severity: ToastSeverity.SUCCESS,
          summary: `${entityNameCapitalized} ${opPastTense}`,
          detail: `${entityNameCapitalized} "${result.data.name}" successfully ${opPastTense}`,
          life: toastTimeout
        })
        resetForm() //TODO: This should only be run on creation right??
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
            summary: `${entityNameCapitalized} ${opNoun} failed`,
            detail: `An error occured ${opPresentTense} ${entityName}: "${errors}"`,
            life: toastTimeout
          })
        }
        else {
          toast.add({
            severity: ToastSeverity.ERROR,
            summary: `${entityNameCapitalized} ${opNoun} failed`,
            detail: `An error occured ${opPresentTense} ${entityName}`,
            life: toastTimeout
          })
          console.dir(errors)
        }
      })
  }
}

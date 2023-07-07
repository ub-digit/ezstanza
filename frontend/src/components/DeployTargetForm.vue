<script>
import {useForm} from 'vee-validate'
import VTextField from '@/components/VTextField.vue'
import {toRaw, ref, inject} from 'vue'
import { useToast } from 'primevue/usetoast'
import { ToastSeverity } from 'primevue/api'
import VColorPickerField from '@/components/VColorPickerField.vue'
import useFormSchema from '@/components/UseFormSchema.js'
import DynamicFormPartial from '@/components/DynamicFormPartial.vue'

export default {
  emits: ['submit'],
  props: {
    deployTarget: {
      type: Object,
      required: true
    },
  },
  setup({ deployTarget }, { emit }) {
    const {handleSubmit, isSubmitting, setFieldValue, useFieldModel, errors} = useForm({
      /*
      validationSchema: {
        name: 'required',
        },
      */
      initialValues: toRaw(deployTarget),
      validateOnMount: false
    })

    const toast = useToast()
    //TODO: Provide global conf for this
    const toastTimeout = 3000

    const api = inject('api')

    const optionsFieldsSchema = ref()

    api.deploy_target.config_form_schema()
      .then(schema => {
        // TODO: 'options' prefix from backend, schema include prefixed fields? What to do?
        const {fieldsSchema, initialValues} = useFormSchema('options', schema)
        optionsFieldsSchema.value = fieldsSchema
        Object.entries(initialValues).map(([fieldName, value]) => {
          //Super ugly, create use-module for this and run in views instead?
          let field = useFieldModel(fieldName)
          if (!field.value && field.value !== 0) {
            field.value = value
          }
        })
      })
      .catch(error => {
        toast.add({
          severity: ToastSeverity.ERROR,
          summary: `An error occured`,
          detail: `Failed to load deploy target options form`,
          life: toastTimeout
        })
      })

    const onSubmit = handleSubmit((values, context) => {
      emit('submit', values, context)
    })

    return {
      optionsFieldsSchema,
      onSubmit,
      isSubmitting,
      errors
    }
  },
  components: {
    VTextField,
    VColorPickerField,
    DynamicFormPartial
  }
}
</script>
<template>
  <form @submit="onSubmit">
    <label for="name" class="block text-900 font-medium mb-2">Name</label>
    <VTextField id="name" name="name"/>

    <label for="color" class="block text-900 font-medium mb-2">Color</label>
    <VColorPickerField id="color" name="color"/>

    <DynamicFormPartial v-if="optionsFieldsSchema" :fieldsSchema="optionsFieldsSchema"/>
    <Button type="submit" :disabled="isSubmitting" label="Save"></Button>
  </form>
</template>

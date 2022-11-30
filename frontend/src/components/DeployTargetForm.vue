<script>
import {useForm} from 'vee-validate'
import VTextField from '@/components/VTextField.vue'
import {toRaw, ref, inject} from 'vue'
import { useToast } from 'primevue/usetoast'
import { ToastSeverity } from 'primevue/api'
import ConfigsDropDown from '@/components/ConfigsDropDown.vue'
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
    const deployTargetValues = toRaw(deployTarget)
    const {handleSubmit, isSubmitting, setFieldValue, useFieldModel, errors} = useForm({
      /*
      validationSchema: {
        name: 'required',
        },
      */
      initialValues: {
        ...deployTargetValues,
      },
      validateOnMount: false
    })

    const defaultConfigId = useFieldModel('default_config_id')

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
      defaultConfigId,
      optionsFieldsSchema,
      onSubmit,
      isSubmitting,
      errors
    }
  },
  components: {
    VTextField,
    ConfigsDropDown,
    DynamicFormPartial
  }
}
</script>
<template>
  <form @submit="onSubmit">
    <label for="name" class="block text-900 font-medium mb-2">Name</label>
    <VTextField id="name" name="name"/>
    <label for="default_config" class="block text-900 font-medium mb-2">Default config</label>
    <ConfigsDropDown
      id="default_config"
      v-model="defaultConfigId"
      class="mb-5"
    />
    <DynamicFormPartial v-if="optionsFieldsSchema" :fieldsSchema="optionsFieldsSchema"/>
    <Button type="submit" :disabled="isSubmitting" label="Save"></Button>
  </form>
</template>

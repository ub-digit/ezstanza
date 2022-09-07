<script>
import {useForm} from 'vee-validate'
import VTextField from '@/components/VTextField.vue'
import {isRef, unref, toRaw} from 'vue'

export default {
  emits: ['submit'],
  props: {
    tag: {
      type: Object,
      required: true
    },
  },
  setup({ tag }, { emit }) {

    const tagValues = toRaw(tag)
    const {handleSubmit, isSubmitting, values, errors} = useForm({
      //validationSchema: schema,
      initialValues: {
        ...tagValues
      }
    })

    const onSubmit = handleSubmit((values, context) => {
      emit('submit', values, context)
    })

    return {
      onSubmit,
      isSubmitting,
      values,
      errors
    }
  },
  components: {
    VTextField
  }
}
</script>
<template>
  <form @submit="onSubmit">
    <label for="name" class="block text-900 font-medium mb-2">Name</label>
    <VTextField id="name" name="name"/>
    <Button type="submit" :disabled="isSubmitting" label="Save"></Button>
  </form>
</template>

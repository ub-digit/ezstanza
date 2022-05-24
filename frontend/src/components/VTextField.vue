<script>
import VField from '@/components/VField.vue'
import InputText from 'primevue/inputtext'
export default {
  inheritAttrs: false,
  props: {
    name: {
      type: String,
      required: true
    },
    containerClass: String,
    helpText: String,
    rules: [String, Object]
  },
  components: {
    VField,
    InputText
  }
}
</script>
<template>
  <VField :name="name" :rules="rules" :class="containerClass" :helpText="helpText" v-slot="{handleBlur, handleChange, value, hasErrors}">
    <InputText :modelValue="value" v-bind="$attrs" @blur="handleBlur" @update:modelValue="handleChange" :class="{'p-invalid': hasErrors}"/>
  </VField>
</template>

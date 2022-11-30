<script>
import VField from '@/components/VField.vue'
import InputNumber from 'primevue/inputnumber'
export default {
  inheritAttrs: false,
  props: {
    name: {
      type: String,
      required: true
    },
    containerClass: String,
    helpText: String,
    rules: [String, Object, Function]
  },
  components: {
    VField,
    InputNumber
  }
}
</script>
<template>
  <VField :name="name" :rules="rules" :class="containerClass" :helpText="helpText" v-slot="{handleBlur, handleChange, value, hasErrors}">
    <InputNumber :modelValue="value" v-bind="$attrs" @blur="handleBlur" @update:modelValue="handleChange" mode="decimal" :class="{'p-invalid': hasErrors}"/>
  </VField>
</template>

<script>
import VField from '@/components/VField.vue'
import Textarea from 'primevue/textarea'
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
    Textarea
  }
}
</script>
<template>
  <VField :name="name" :rules="rules" :class="containerClass" :helpText="helpText" v-slot="{handleBlur, handleChange, value, hasErrors}">
    <Textarea :modelValue="value" v-bind="$attrs" @blur="handleBlur" @update:modelValue="handleChange" :class="{'p-invalid': hasErrors}"/>
  </VField>
</template>

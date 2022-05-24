<script>
//import { computed } from 'vue'
import { useField } from 'vee-validate'
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
  setup({ name, rules }) {
    const { value, handleBlur, errorMessage, errors } = useField(name, rules)
    //const hasError = computed(() => !!errorMessage)
    //const hasError = computed(() => errors.length )
    return {
      errors,
      value,
      handleBlur,
      errorMessage
      //hasError
    }
  },
  components: {
    InputText
  }
}

// TODO: Style on .field instead of mb-4
// increase margin if helptext?
</script>
<template>
  <div class="field mb-5" :class="containerClass">
    <InputText v-model="value" v-bind="$attrs" @blur="handleBlur" :class="{ 'p-invalid': !!errorMessage }"/>
    <small class="field-text" v-if="!!errorMessage" :class="{ 'p-error': !!errorMessage }">
      {{ errorMessage }}
    </small>
    <small class="field-text text-600" v-else-if="helpText">{{ helpText }}</small>
  </div>
</template>
<style>
.field-text {
  position: absolute;
  top: 100%;
  left: 0;
}
</style>

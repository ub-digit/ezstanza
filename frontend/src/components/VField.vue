<script>
import { useField } from 'vee-validate'
export default {
  props: {
    name: {
      type: String,
      required: true
    },
    helpText: String,
    rules: [String, Object]
  },
  setup({ name, rules }) {
    const { value, handleBlur, handleChange, errorMessage, meta } = useField(name, rules)
    //const hasError = computed(() => !!errorMessage)
    //const hasError = computed(() => errors.length )
    return {
      value,
      handleBlur,
      handleChange,
      errorMessage,
      meta
      //hasError
    }
  }
}

// TODO: Style on .field instead of mb-4
// increase margin if helptext?
</script>
<template>
  <div class="field mb-5">
    <slot :handleBlur="handleBlur" :handleChange="handleChange" :value="value" :hasErrors="!!errorMessage" :meta="meta"></slot>
    <small class="field-text" v-if="!!errorMessage" :class="{ 'p-error': !!errorMessage }">
      {{ errorMessage }}
    </small>
    <small class="field-text text-600" v-else-if="helpText">{{ helpText }}</small>
  </div>
</template>
<style>
.field {
  position: relative;
}
.field-text {
  position: absolute;
  top: 100%;
  left: 0;
}
</style>

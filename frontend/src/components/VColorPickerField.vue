<script>
import VField from '@/components/VField.vue'
import ColorPicker from 'primevue/colorpicker'
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
    ColorPicker
  }
}
</script>
<template>
  <VField :name="name" :rules="rules" :class="containerClass" :helpText="helpText" v-slot="{handleChange, value, hasErrors}">
    <!-- TODO: p-invalid?? -->
    <!-- TODO: appendTo="self" ?? -->
    <ColorPicker :modelValue="value" v-bind="$attrs" @update:modelValue="handleChange" :class="{'p-invalid': hasErrors}"/>
  </VField>
</template>

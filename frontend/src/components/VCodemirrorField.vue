<script>
import VField from '@/components/VField.vue'
import { Codemirror } from 'vue-codemirror'
export default {
  inheritAttrs: false,
  emits: ['change'],
  props: {
    name: {
      type: String,
      required: true
    },
    containerClass: String,
    helpText: String,
    rules: [String, Object]
  },
  setup(_props, {emit})  {
    const onChange = (value, viewUpdate) => {
      emit('change', value, viewUpdate)
    }
    return {
      onChange
    }
  },
  components: {
    VField,
    Codemirror
  }
}
</script>
<template>
  <VField :name="name" :rules="rules" :class="containerClass" :helpText="helpText" v-slot="{handleBlur, handleChange, value, hasErrors}">
    <Codemirror
      :modelValue="value"
      @update:modelValue="handleChange"
      @change="onChange"
      @blur="handleBlur"
      v-bind="$attrs"
      :style="{ height: '400px' }"
      :indent-with-tabs="true"
    />
  </VField>
</template>

<script>
export default {
  emits: ['update:modelValue'],
  props: {
    modelValue: {
      type: Object,
      required: true
    },
  },
  /*
  setup({ stanza }) {
  }
  */
}
</script>
<template>
  <div>{{ modelValue.id }}</div>
</template>


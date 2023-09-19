<script>
import { ref, toRef, watch } from 'vue'
import AutoComplete from 'primevue/autocomplete'

export default {
  emits: ['update:modelValue', 'change'],
  props: {
    optionValue: {
      type: String,
      required: true
    },
    options: {
      type: Array,
      required: true
    },
    modelValue: {
      required: true
    },
  },
  setup(props, { emit }) {

    const model = ref()

    const parentModel = toRef(props, 'modelValue')

    watch(parentModel, (newValue) => {
      if (Array.isArray(newValue)) {
        model.value = newValue.map(id => {
          return props.options.find(elem => elem[props.optionValue] == id)
        })
      }
      else if (newValue) {
        model.value = props.options.find(elem => elem[props.optionValue] == newValue) || newValue
      }
      else {
        model.value = newValue
      }
    }, { immediate: true })

    const onModelUpdate = (event) => {
      if (Array.isArray(event)) {
        const value = event.map(elem => elem[props.optionValue])
        emit("update:modelValue", value)
        emit("change", value)
      }
      else if(typeof(event) === "object") {
        emit("update:modelValue", event[props.optionValue])
        emit("change", event[props.optionValue])
      }
      else {
        emit("update:modelValue", event)
      }
      if (!event) {
        emit("change", event)
      }
    }

    return {
      model,
      onModelUpdate
    }
  },
  components: {
    AutoComplete
  }
}
</script>
<template>
  <AutoComplete :modelValue="model" @update:modelValue="onModelUpdate"/>
</template>

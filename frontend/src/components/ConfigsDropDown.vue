<script>
import {toRaw, ref, inject} from 'vue'
import DropDown from 'primevue/dropdown'

export default {
  emits: ['update:modelValue'],
  props: {
    modelValue: {
      type: Number,
      default: null
    }
  },
  setup(_props, { emit }) {
    const api = inject('api')
    const configOptions = ref([])
    api.configs.list().then(result => {
      configOptions.value = result.data.map(
        config => {
          return {
            name: config.name,
            id: config.id
          }
        }
      )
    })
    return {
      configOptions
    }
  },
  components: {
    DropDown
  }
}

</script>
<template>
  <DropDown
    :modelValue="modelValue"
    @change="$emit('update:modelValue', $event.value)"
    :options="configOptions"
    dataKey="id"
    optionLabel="name"
    optionValue="id"
    placeholder="Select"
    class="-column-filter"
  />

</template>

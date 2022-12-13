<script>
import {toRaw, ref, inject} from 'vue'
import DropDown from 'primevue/dropdown'

export default {
  emits: ['update:modelValue', 'change'],
  props: {
    modelValue: {
      type: [Number, Object],
      default: null
    },
    revisions: {
      type: Boolean,
      default: false
    },
    placeholder: {
      type: String,
      default: "Any"
    }
  },
  setup(props, { emit }) {
    const api = inject('api')
    const configOptions = ref([])
    const params = props.revisions ? { includes: ['revisions'] } : {}
    api.configs.list(params).then(result => {
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
    @update:modelValue="$emit('update:modelValue', $event)"
    @change="$emit('change', $event)"
    :options="configOptions"
    dataKey="id"
    optionLabel="name"
    :placeholder="placeholder"
  />
</template>

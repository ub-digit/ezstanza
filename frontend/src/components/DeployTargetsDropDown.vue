<script>
import {toRaw, ref, inject} from 'vue'
import MultiSelect from 'primevue/multiselect'

export default {
  emits: ['update:modelValue', 'change'],
  props: {
    modelValue: {
      type: [Number, Object],
      default: null
    },
    placeholder: {
      type: String,
      default: "Any"
    }
  },
  setup(props, { emit }) {
    const api = inject('api')
    const deployTargetOptions = ref([])
    api.deploy_targets.list().then(result => {
      deployTargetOptions.value = result.data.map(
        deployTarget => {
          let id = deployTarget.current_deployment ?
            deployTarget.current_deployment.id : -1;
          return {
            name: deployTarget.name,
            id: id
          }
        }
      )
    })
    return {
      deployTargetOptions
    }
  },
  components: {
    MultiSelect
  }
}

</script>
<template>
  <MultiSelect
    :modelValue="modelValue"
    @update:modelValue="$emit('update:modelValue', $event)"
    @change="$emit('change', $event)"
    :options="deployTargetOptions"
    optionLabel="name"
    optionValue="id"
    :placeholder="placeholder"
  />
</template>

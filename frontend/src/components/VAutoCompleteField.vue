<script>
import AutoComplete from 'primevue/autocomplete'
import VField from '@/components/VField.vue'
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
    AutoComplete
  }
}
</script>
<template>
  <VField :name="name" :rules="rules" :class="containerClass" :helpText="helpText" v-slot="{handleChange, value, hasErrors}">
    <AutoComplete :modelValue="value" v-bind="$attrs" @update:modelValue="handleChange" :class="{'p-invalid': hasErrors}">
      <template v-for="(_, name) in $slots" v-slot:[name]="slotProps">
        <slot v-if="slotProps" :name="name" v-bind="slotProps" />
        <slot v-else :name="name" />
      </template>
    </AutoComplete>
  </VField>
</template>

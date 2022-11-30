<script>
import VTextField from '@/components/VTextField.vue'
import VNumberField from '@/components/VNumberField.vue'

export default {
  props: {
    fieldsSchema: {
      type: Object,
      required: true
    }
  },
  setup(_props, _context) {

  },
  //TODO: provide globally
  components: {
    VTextField,
    VNumberField
  }
}
</script>
<template>
  <template
    v-for="{ name, component, label, help_text } in fieldsSchema"
    :key="name"
  >
    <!-- TODO: id prefix or replace . with _ -->
    <label :for="name" class="block text-900 font-medium mb-2">
      {{ label }}
    </label>
    <component :is="component.is" :id="name" :name="name" :helpText="help_text" v-bind="component.options"/>
  </template>
</template>

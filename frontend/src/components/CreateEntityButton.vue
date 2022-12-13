<script>
import Button from 'primevue/button'

export default {
  props: {
    destinationPath: {
      type: String,
      required: true
    },
    createRouteName: {
      type: String,
      required: true
    },
  },
  /*
  setup({ props }) {

  },
  */
  components: {
    Button
  }
}
</script>
<template>
  <router-link
    custom
    :to="{ name: createRouteName, query: { destination: destinationPath } }"
    v-slot="{ navigate }"
  >
    <Button label="New" icon="pi pi-plus" class="p-button-success mr-2" @click="navigate"/>
  </router-link>
</template>

<script setup>
import Menu from 'primevue/menu'
import { ref } from 'vue';

const items = ref([
  {
    label: 'New',
    items: [
      {
        label: 'Stanza',
        icon: 'pi pi-fw pi-file',
      }
    ]
  },
  {
    label: 'Test',
    items: [
      {
        label: 'Example',
        icon: 'pi pi-fw pi-cog'
      }
    ]
  }
])
</script>
<template>
  <Menu :model="items" />
</template>

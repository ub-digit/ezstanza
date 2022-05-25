<script>
import { useAuth } from '@websanova/vue-auth/src/v3.js'
import Menu from 'primevue/menu'
import { ref } from 'vue';

export default {
  setup() {
    const auth = useAuth()
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
      },
      {
        label: 'User',
        items: [
          {
            label: 'Sign out',
            icon: 'pi pi-fw pi-sign-out',
            command: () => { auth.logout() }
          }
        ]
      }
    ])
    return { items }
  },
  components: {
    Menu
  }
}

</script>
<template>
  <Menu :model="items" />
</template>

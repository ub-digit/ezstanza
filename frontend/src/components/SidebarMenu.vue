<script>
import { useAuth } from '@websanova/vue-auth/src/v3.js'
import Menu from 'primevue/menu'
import { ref } from 'vue';

export default {
  setup() {
    const auth = useAuth()
    const items = ref([
      {
        label: 'Configuration',
        items: [
          {
            label: 'Stanzas',
            icon: 'pi pi-fw pi-file',
            to: '/stanzas'
          }, {
            label: 'Configs',
            icon: 'pi pi-fw pi-book',
            to: '/configs'
          }, {
            label: 'Tags',
            icon: 'pi pi-fw pi-tags',
            to: '/tags'
          },
        ]
      },
      {
        label: 'Settings',
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

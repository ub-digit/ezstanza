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
            label: 'Deployments',
            icon: 'pi pi-fw pi-cloud-upload',
            to: '/deployments'
          }, {
            label: 'Deploy targets',
            icon: 'pi pi-fw pi-server',
            to: '/deploy_targets'
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

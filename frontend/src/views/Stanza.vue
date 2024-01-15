<script>
import { watch, ref, inject, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import TabMenu from 'primevue/tabmenu'
import { RouterLink, RouterView } from 'vue-router'

export default {
  setup() {
    const route = useRoute()
    const router = useRouter()

    const active = ref(0)
    /*
    const items = ref([
      {
        label: 'Edit',
        icon: 'pi pi-fw pi-pencil',
        route: '/'
      },
      {
        label: 'Revisions',
        icon: 'pi pi-fw pi-file',
        route: '/revisions'
      }
      ])
    */

    const items = computed(() => {
      const basePath = `/stanzas/${route.params.id}`
      return [
        {
          label: 'Edit',
          icon: 'pi pi-fw pi-pencil',
          route: basePath
        }, {
          label: 'Revisions',
          icon: 'pi pi-fw pi-file',
          route: `${basePath}/revisions`
        }
      ]
    })

    onMounted(() => {
      active.value = items.value.findIndex((item) => route.path === router.resolve(item.route).path);
    })
    watch(
      route,
      () => {
        active.value = items.value.findIndex((item) => route.path === router.resolve(item.route).path);
      },
      { immediate: true }
    )

    return {
      active,
      items
    }
  },
  components: {
    TabMenu,
    RouterLink,
    RouterView
  }
}
</script>
<template>
  <TabMenu v-model:activeIndex="active" :model="items">
    <template #item="{ label, item, props }">
      <RouterLink v-if="item.route" v-slot="routerProps" :to="item.route" custom>
        <a :href="routerProps.href" v-bind="props.action" @click="($event) => routerProps.navigate($event)" @keydown.enter.space="($event) => routerProps.navigate($event)">
          <span v-bind="props.icon" />
          <span v-bind="props.label">{{ label }}</span>
        </a>
      </RouterLink>
    </template>
  </TabMenu>
  <RouterView/>
</template>

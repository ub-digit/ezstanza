<script>
import { RouterLink, RouterView } from 'vue-router'
import SidebarMenu from '@/components/SidebarMenu.vue'
import { useLoaderStore } from '@/stores/loader'
import { storeToRefs } from 'pinia'
import Toast from 'primevue/toast'
import DynamicDialog from 'primevue/dynamicdialog';

export default {
  setup() {
    const loaderStore = useLoaderStore()
    const { loading } = storeToRefs(loaderStore)
    return {
      loading
    }
  },
  components: {
    RouterLink,
    RouterView,
    SidebarMenu,
    Toast,
    DynamicDialog
  }
}
</script>

<template>
  <Toast />
  <DynamicDialog />
  <header class="surface-overlay shadow-2 py-3 px-5 flex align-items-center justify-content-between">
    <img src="@/assets/logo.svg" alt="Logo" height="50">
    <nav>
      <RouterLink to="/">Home</RouterLink>
    </nav>
  </header>
  <div class="grid">
    <nav v-show="$auth.check()" class="col-fixed" style="width: 200px;">
      <SidebarMenu />
    </nav>
    <div class="col p-5">
      <div v-if="loading">
        Loading....
      </div>
      <RouterView />
    </div>
  </div>
</template>

<style>
@import '@/assets/base.css';
/* purgecss start ignore */
@import '@/assets/theme.css';
@import '@/assets/vue-diff.css';
/* purgecss end ignore */
</style>
<style lang="scss">
@import '@/assets/main.scss';
</style>

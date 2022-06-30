import { createRouter, createWebHistory } from 'vue-router'
import Login from '../views/Login.vue'
import Home from '../views/Home.vue'
import EditStanza from '../views/EditStanza.vue'
import ListStanzas from '../views/ListStanzas.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'Home',
      component: Home,
      meta: { auth: true }
    }, {
      path: '/login',
      name: 'Login',
      component: Login,
      meta: { auth: false }
    }, {
      path: '/stanzas',
      name: 'ListStanzas',
      component: ListStanzas,
      meta: { auth: true }
    }, {
      path: '/stanzas/:id',
      name: 'EditStanza',
      component: EditStanza,
      meta: { auth: true }
    }
  ]
})

export default (app) => {
  app.router = router
  app.use(router)
}

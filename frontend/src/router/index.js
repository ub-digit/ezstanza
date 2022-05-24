import { createRouter, createWebHistory } from 'vue-router'
import Login from '../views/Login.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'login',
      component: Login
    }, {
      path: '/login',
      name: 'login',
      component: Login,
      meta: { auth: false }
    }
  ]
})

export default router

import { createRouter, createWebHistory } from 'vue-router'
import Login from '../views/Login.vue'
import Home from '../views/Home.vue'

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
    }
  ]
})

export default (app) => {
  app.router = router
  app.use(router)
}

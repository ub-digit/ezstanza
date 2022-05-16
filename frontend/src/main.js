import { createApp } from 'vue'
import { createPinia } from 'pinia'
import axios from 'axios';
import {createAuth} from '@websanova/vue-auth';
import driverAuthBearer from './plugins/driver_auth_bearer.js';
import driverHttpAxios from '@websanova/vue-auth/dist/drivers/http/axios.1.x.esm.js';
import driverRouterVueRouter from '@websanova/vue-auth/dist/drivers/router/vue-router.2.x.esm.js';

import App from './App.vue'
import PrimeVue from 'primevue/config';
import router from './router'

import 'primevue/resources/themes/bootstrap4-dark-blue/theme.css';
import 'primevue/resources/primevue.min.css';
import 'primeicons/primeicons.css';

var auth = createAuth({
  plugins: {
    http: axios,
    router: router
  },
  drivers: {
    http: driverHttpAxios,
    auth: driverAuthBearer,
    router: driverRouterVueRouter,
  },
  options: {
    //rolesKey: 'type',
    //notFoundRedirect: {name: 'user-account'},
  }
});

const app = createApp(App)
  .use(createPinia())
  .use(PrimeVue)
  .use(router)
  .use(auth)
  .mount('#app')

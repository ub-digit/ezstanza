import { createApp } from 'vue'
import { createPinia } from 'pinia'
import axios from 'axios';
import { createAuth } from '@websanova/vue-auth';
import driverAuthBearer from './plugins/driver_auth_bearer.js';
import driverHttpAxios from '@websanova/vue-auth/dist/drivers/http/axios.1.x.esm.js';
import driverRouterVueRouter from '@websanova/vue-auth/dist/drivers/router/vue-router.2.x.esm.js';

import App from './App.vue'
import PrimeVue from 'primevue/config';
import router from './router'

// import 'primevue/resources/themes/bootstrap4-dark-blue/theme.css';
import "primevue/resources/themes/lara-light-indigo/theme.css";
import 'primevue/resources/primevue.min.css';
import 'primeicons/primeicons.css';
import 'primeflex/primeflex.css';

axios.defaults.baseURL = 'http://127.0.0.1:4000/api' //process.env.VUE_APP_BASE_URL

var auth = createAuth({
  plugins: {
    http: axios,
    router: router
  },
  drivers: {
    http: driverHttpAxios,
    auth: driverAuthBearer,
    router: driverRouterVueRouter
  },
  options: {
    //rolesKey: 'type',
    //notFoundRedirect: {name: 'user-account'},
    loginData: {
      url: '/session',
      method: 'POST',
      redirect: '/',
      fetchUser: false
      //customToken: (response) => response.data['token'],
    },
    logoutData: {
      url: '/session/delete',
      method: 'POST',
      redirect: '/login',
      makeRequest: false //????
    },
    fetchData: {
      url: '/session/user',
      method: 'GET',
      interval: 0,
      enabled: true
    },
    refreshData: {
      url: '/session/renew',
      method: 'POST',
      interval: 30,
      enabled: true
    }
  }
});

import InputText from 'primevue/inputtext';
import Checkbox from 'primevue/checkbox';
import Button from 'primevue/button';

const app = createApp(App)
  .use(createPinia())
  .use(PrimeVue)
  .use(router)
  .use(auth)
  .component('InputText', InputText)
  .component('Checkbox', Checkbox)
  .component('Button', Button)
  .mount('#app')

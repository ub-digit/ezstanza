import { createApp } from 'vue'

import App from './App.vue'
import PrimeVue from 'primevue/config'
import router from './router'
import auth from './plugins/auth'
import http from './plugins/http'
import pinia from './plugins/pinia'
import dayjs from './plugins/dayjs'
//import userSocket from './plugins/user_socket'
import api_service from './plugins/api_service'
import ToastService from 'primevue/toastservice'
import DialogService from 'primevue/dialogservice'
import { Diff } from 'diff'

//import 'primevue/resources/themes/bootstrap4-light-blue/theme.css';
import "primevue/resources/themes/lara-light-indigo/theme.css"
import 'primevue/resources/primevue.min.css'
import 'primeicons/primeicons.css'
import 'primeflex/primeflex.css'
//import '@/assets/main.scss'

import Button from 'primevue/button' //TODO: Import locally instead?

//TODO: Put in import
import { defineRule } from 'vee-validate'

defineRule('required', (value) => {
  if (!value && value !== 0 || typeof value === 'string' && !value.length) {
    return 'This field is required'
  }
  return true
})

const app = createApp(App)
  .use(PrimeVue)
  .use(ToastService)
  .use(DialogService)
  .use(pinia)
  .use(http)
  .use(api_service)
  .use(router)
  .use(auth)
  .use(dayjs)
  .use(app => app.provide('diff', Diff))
  //.use(userSocket)
  .component('Button', Button)
  .mount('#app')

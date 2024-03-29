import { createApp } from 'vue'

import App from './App.vue'
import PrimeVue from 'primevue/config'
import router from './router'
import auth from './plugins/auth'
import http from './plugins/http'
import pinia from './plugins/pinia'
import dayjs from './plugins/dayjs'
import userSocket from './plugins/user_socket'
import api_service from './plugins/api_service'
import ToastService from 'primevue/toastservice'
import DialogService from 'primevue/dialogservice'
import VueDiff from 'vue-diff'

//import { Diff } from 'diff'

//import 'primevue/resources/themes/bootstrap4-light-blue/theme.css';
/* purgecss start ignore */
//import 'primevue/resources/themes/lara-light-indigo/theme.css'
/* purgecss end ignore */
import 'primeicons/primeicons.css'
import 'primeflex/primeflex.css'
// import 'vue-diff/dist/index.css'

import Button from 'primevue/button' //TODO: Import locally instead?
import Tooltip from 'primevue/tooltip'

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
  .use(userSocket)
  .use(dayjs)
  .use(VueDiff, {
    componentName: 'VueDiff'
  })
  //.use(app => app.provide('diff', Diff))
  .component('Button', Button)
  .directive('tooltip', Tooltip)
  .mount('#app')

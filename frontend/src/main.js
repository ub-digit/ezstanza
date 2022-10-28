import { createApp } from 'vue'

import App from './App.vue'
import PrimeVue from 'primevue/config'
import router from './router'
import auth from './plugins/auth'
import http from './plugins/http'
import pinia from './plugins/pinia'
import dayjs from './plugins/dayjs'
import api_service from './plugins/api_service'
import ToastService from 'primevue/toastservice'
import DialogService from 'primevue/dialogservice'

// import 'primevue/resources/themes/bootstrap4-dark-blue/theme.css';
import "primevue/resources/themes/lara-light-indigo/theme.css"
import 'primevue/resources/primevue.min.css'
import 'primeicons/primeicons.css'
import 'primeflex/primeflex.css'

import InputText from 'primevue/inputtext'
import Checkbox from 'primevue/checkbox'
import Button from 'primevue/button'

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
  .component('InputText', InputText) //TODO: remove this and import in components
  .component('Checkbox', Checkbox)
  .component('Button', Button)
  .mount('#app')

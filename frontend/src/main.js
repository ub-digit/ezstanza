import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import PrimeVue from 'primevue/config'
import router from './router'
import auth from './plugins/auth.js'
import http from './plugins/http.js'

// import 'primevue/resources/themes/bootstrap4-dark-blue/theme.css';
import "primevue/resources/themes/lara-light-indigo/theme.css"
import 'primevue/resources/primevue.min.css'
import 'primeicons/primeicons.css'
import 'primeflex/primeflex.css'

import InputText from 'primevue/inputtext'
import Checkbox from 'primevue/checkbox'
import Button from 'primevue/button'

const app = createApp(App)
  .use(createPinia())
  .use(PrimeVue)
  .use(http)
  .use(router)
  .use(auth)
  .component('InputText', InputText)
  .component('Checkbox', Checkbox)
  .component('Button', Button)
  .mount('#app')

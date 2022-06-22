import { createPinia } from 'pinia'
import api from '@/services/api'

export default (app) => {
  const pinia = createPinia(({store, options}) => {
    if (options.api) {
      store.api = api
    }
  })
  app.use(createPinia())
}

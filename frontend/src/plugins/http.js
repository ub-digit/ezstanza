import axios from 'axios'
import { useLoaderStore } from '@/stores/loader'

axios.defaults.baseURL = 'http://127.0.0.1:4000/api' //process.env.VUE_APP_API_URL
axios.defaults.showLoader = true

export default (app) => {
  app.axios = axios;
  app.$http = axios;

  app.config.globalProperties.axios = axios;
  app.config.globalProperties.$http = axios;

  /* Place this in separate module? */

  const loaderStore = useLoaderStore()

  axios.interceptors.request.use(
    config => {
      if (config.showLoader) {
        loaderStore.pending()
      }
      return config
    },
    error => {
      if (error.config.showLoader) {
        loaderStore.done()
      }
      return Promise.reject(error)
    }
  )
  axios.interceptors.response.use(
    response => {
      if (response.config.showLoader) {
        loaderStore.done()
      }
      return response;
    },
    error => {
      if (error.response.config.showLoader) {
        loaderStore.done()
      }
      return Promise.reject(error);
    }
  )
}

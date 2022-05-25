import axios from 'axios'

axios.defaults.baseURL = 'http://127.0.0.1:4000/api' //process.env.VUE_APP_API_URL

export default (app) => {
  app.axios = axios;
  app.$http = axios;

  app.config.globalProperties.axios = axios;
  app.config.globalProperties.$http = axios;
}

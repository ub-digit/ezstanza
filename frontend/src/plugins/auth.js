import { createAuth } from '@websanova/vue-auth';
import driverAuthBearer from '@/plugins/driver_auth_bearer.js';
import driverHttpAxios from '@websanova/vue-auth/dist/drivers/http/axios.1.x.esm.js';
import driverRouterVueRouter from '@websanova/vue-auth/dist/drivers/router/vue-router.2.x.esm.js';

export default (app) => {
  var auth = createAuth({
    plugins: {
      http: app.axios,
      router: app.router
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
        makeRequest: true
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
  })
  app.use(auth)
}

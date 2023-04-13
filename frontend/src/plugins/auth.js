import { createAuth } from '@websanova/vue-auth'
import driverAuthBearer from '@/plugins/driver_auth_bearer.js'
import driverHttpAxios from '@websanova/vue-auth/dist/drivers/http/axios.1.x.esm.js'
import driverRouterVueRouter from '@websanova/vue-auth/dist/drivers/router/vue-router.2.x.esm.js'

// Bring in Phoenix channels client library:
import { Socket } from "phoenix"
// import { useAuth } from '@websanova/vue-auth/src/v3.js'
import { watch } from 'vue'
// import mitt from 'mitt'

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

  const setupSocket = (token) => {
    console.log('setting up socket')
    let socket = new Socket('ws://127.0.0.1:4000/socket', {params: {token: token }})
    socket.connect()
    app.provide('socket', socket)
  }

  if (auth.token()) {
    console.log('token exists')
    setupSocket(auth.token())
  }
  else {
    console.log('watching')
    watch(auth.$vm.state.authenticated, () => {
      if (auth.$vm.state.authenticated) {
        setupSocket(auth.token())
      }
      /*
      let token = auth.token()
      if (token) {
        if (!socket) {
          // Token changed, need to disconnect and connect with new token
          socket = new Socket('ws://127.0.0.1:4000/socket', {params: {token: token}})

          // TODO: handle case where new token, need to close down current connection
          // and reconnect?
          console.log(token)
          //TODO process.env.VUE_APP_SOCKET_URL
          let socket = new Socket('ws://127.0.0.1:4000/socket', {params: {token: token}})
          socket.connect()

          let channel = socket.channel("deployment", {})
          ;[
            "deployment_status_change"
          ].forEach(event => {
            channel.on(event, payload => {
              emitter.emit(payload)
            })
          })
          channel.join()
            .receive("ok", resp => { console.log("Joined successfully", resp) })
            .receive("error", resp => { console.log("Unable to join", resp) })
        }
      }
      else if(socket) {
        socket.disconnect()
      }
      */
    })
  }

}

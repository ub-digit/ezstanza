// Bring in Phoenix channels client library:
import { Socket } from "phoenix"
import { watch } from 'vue'

export default (app) => {

  const auth = app.auth //app.config.globalProperties.$auth?

  // TODO: This sucks, theoretical race condition
  // in practice will not happen, but how to solve in better way?

  let socket = null
  let deploymentChannel = null

  const channels = {
    deployment: null
  }

  let provided = false

  const setupSocket = (token) => {
    if (!socket) {
      socket = new Socket(APP_CONFIG['backend_socket_url'], {params: {token: token }})
      socket.connect()
      deploymentChannel = socket.channel('deployment', {})
      deploymentChannel.join()
        .receive("ok", resp => { console.log("Joined successfully", resp) })
        .receive("error", resp => { console.log("Unable to join", resp) })
      channels.deployment = deploymentChannel

      if (!provided) {
        provided = true
        app.provide('channels', channels)
      }
    }
  }

  auth.load().then(() => {
    console.log('loaded', auth.token())
  })

  watch(auth.$vm.state, (state, oldState) => {
    //console.log('new state', JSON.stringify(state))
    //console.log('old state', JSON.stringify(oldState))
  })

  if (auth.token()) {
    setupSocket(auth.token())
  }
  else {
    watch(auth.$vm.state, (state) => {
      if (state.authenticated) {
        setupSocket(auth.token())
      }
      else if(socket) {
        socket.disconnect()
        socket = null
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

import { defineStore } from 'pinia'

export const useLoaderStore = defineStore('loader', {
  state: () => ({
      loading: false,
      requestsPending: 0
  }),
  actions: {
    show() {
      this.loading = true
    },
    hide() {
      this.loading = false
    },
    pending() {
      if (this.requestsPending === 0) {
        this.show()
      }
      this.requestsPending++;
    },
    done() {
      if (this.requestsPending >= 1) {
        this.requestsPending--
      }
      if (this.requestsPending === 0) {
        this.hide()
      }
    }
  }
})

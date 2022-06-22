import api from '@/services/api'

export default (app) => {
  app.provide('api', api)
}

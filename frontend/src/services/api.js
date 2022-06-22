import axios from 'axios'

class BaseApiService {
  // Note: you may want to store this info in .env file
  #baseUrl = 'http://127.0.0.1:4000/api' //process.env.VUE_APP_API_URL
  #resource

  constructor(resource) {
    if (!resource) throw new Error("Resource is not provided")
    this.#resource = resource
  }

  endpointUrl() {
    return `${this.#baseUrl}/${this.#resource}`
  }

  handleErrors(error) {
    if (error.response.data === 'object' && 'errors' in error.response.data) {
      throw error.response.data.errors
    }
    else {
      // TODO: What to throw?
      console.log("error")
      console.dir(error)
      throw "An error occured"
    }
  }

}

class ResourceApiService extends BaseApiService {

  // Can remove this?
  constructor(resource) {
    super(resource)
  }
  //get?
  fetch(id) {
    return axios.get(`${this.endpointUrl()}/${id}`)
      .then(response => {
        return response.data.data
      })
      .catch(this.handleErrors)
  }
  //index/find/get_all/all?
  async index() {

  }

  async create(data) {

  }

  async update(id, data) {

  }

  async delete(id) {

  }

}

class StanzasApiService extends ResourceApiService {
  constructor() {
    super('stanzas')
  }
}
const api = {
  stanzas: new StanzasApiService()
}

export default api

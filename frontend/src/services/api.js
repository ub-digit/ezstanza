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
    if (typeof error.response.data === 'object' && 'errors' in error.response.data) {
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
  fetch(id, params) {
    const options = params ? {
      params: params
    } : {}

    return axios.get(`${this.endpointUrl()}/${id}`, options)
      .then(response => {
        return response.data
      })
      .catch(this.handleErrors)
  }

  list(params) {
    const options = params ? {
      params: params
    } : {}

    return axios.get(this.endpointUrl(), options)
      .then(response => {
        return response.data
      })
      .catch(this.handleErrors)
  }

  create(data) {
    return axios.post(`${this.endpointUrl()}`, data)
      .then(response => {
        return response.data
      })
      .catch(this.handleErrors)
  }

  update(id, data) {
    return axios.put(`${this.endpointUrl()}/${id}`, data)
      .then(response => {
        return response.data
      })
      .catch(this.handleErrors)
  }

  delete(id) {
    return axios.delete(`${this.endpointUrl()}/${id}`)
      .then(response => {
        return response.data
      })
      .catch(this.handleErrors)
  }
}

class StanzasApiService extends ResourceApiService {
  constructor() {
    super('stanzas')
  }
}

class StanzaRevisoinsApiService extends ResourceApiService {
  constructor() {
    super('stanzas_revisions')
  }
}

class TagsApiService extends ResourceApiService {
  constructor() {
    super('tags')
  }
}

class ConfigsApiService extends ResourceApiService {
  constructor() {
    super('configs')
  }
}

const api = {
  stanzas: new StanzasApiService(),
  tags: new TagsApiService(),
  configs: new ConfigsApiService()
}

export default api

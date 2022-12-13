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
    throw error
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
      .then(response => response.data)
      .catch(this.handleErrors)
  }

  list(params) {
    const options = params ? {
      params: params
    } : {}

    return axios.get(this.endpointUrl(), options)
      .then(response => response.data)
      .catch(this.handleErrors)
  }

  create(data) {
    return axios.post(`${this.endpointUrl()}`, data)
      .then(response => response.data)
      .catch(this.handleErrors)
  }

  update(id, data) {
    return axios.put(`${this.endpointUrl()}/${id}`, data)
      .then(response => response.data)
      .catch(this.handleErrors)
  }

  delete(id) {
    return axios.delete(`${this.endpointUrl()}/${id}`)
      .then(response => response.data)
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
    super('stanza_revisions')
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

class UsersApiService extends ResourceApiService {
  constructor() {
    super('users')
  }
}

class DeployTargetsApiService extends ResourceApiService {
  constructor() {
    super('deploy_targets')
  }
}

class DeployTargetApiService extends BaseApiService {
  constructor() {
    super('deploy_target')
  }

  config_form_schema() {
    return axios.get(`${this.endpointUrl()}/frontend_options_form_schema`)
      .then(response => response.data)
      .catch(this.handleErrors)
  }

}

class DeploymentsApiService extends ResourceApiService {
  constructor() {
    super('deployments')
  }
}


const api = {
  stanzas: new StanzasApiService(),
  stanza_revisions: new StanzaRevisoinsApiService(),
  tags: new TagsApiService(),
  configs: new ConfigsApiService(),
  users: new UsersApiService(),
  deploy_targets: new DeployTargetsApiService(),
  deploy_target: new DeployTargetApiService(),
  deployments: new DeploymentsApiService()
}

export default api

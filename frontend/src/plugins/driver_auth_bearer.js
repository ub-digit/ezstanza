export default {
  request(req, token) {
    this.drivers.http.setHeaders.call(this, req, {
      Authorization: 'Bearer ' + token
    });
  },

  response(res) {
    if (res.data && res.data.data && res.data.data.access_token) {
      return res.data.data.access_token
    }
  }
}

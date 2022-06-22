export default {
  request: function (req, token) {
    this.drivers.http.setHeaders.call(this, req, {
      Authorization: 'Bearer ' + token
    });
  },

  response: function (res) {
    if (res.data.data && res.data.data.access_token) {
      return res.data.data.access_token
    }
  }
}

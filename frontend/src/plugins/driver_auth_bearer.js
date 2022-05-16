export default {

    request: function (req, token) {
        this.drivers.http.setHeaders.call(this, req, {
            Authorization: 'Bearer ' + token
        });
    },

    response: function (res) {
        if (res.data.token) {
            return res.data.token;
        }
    }
};

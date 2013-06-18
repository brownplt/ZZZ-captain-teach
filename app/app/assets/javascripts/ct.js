function ct_ajax(url, params) {
    if (!params.hasOwnProperty("failure")) {
        params.failure = function (error) {
            console.error(error);
        }
    }
    $.ajax(url, params);
}

// ajax 전처리
$(document).ajaxSend(function (event, jqXHR, ajaxOptions) {
    // Add RequestVerificationToken
    if (
        ajaxOptions.contentType === 'application/x-www-form-urlencoded; charset=utf-8' &&
        ajaxOptions.enctype !== 'multipart/form-data' &&
        (ajaxOptions.type.toUpperCase() === 'POST' || ajaxOptions.type.toUpperCase() === 'PATCH' || ajaxOptions.type.toUpperCase() === 'DELETE')
    ) {
        var antiForgeryToken = $('input[name="__RequestVerificationToken"]', $('#__AjaxAntiForgeryForm')).val();

        ajaxOptions.data +=
            '&' +
            $.param({
                __RequestVerificationToken: antiForgeryToken,
            });
    }
});
// ajax 후처리
$.ajaxPrefilter(function (options, originalOptions, jqXHR) {
    var success = options.success;
    options.success = function (data, originalOptions, jqXHR) {
        if (typeof success === 'function') return success(data, originalOptions, jqXHR);
    };

    var error = options.error;
    options.error = function (jqXHR, textStatus, errorThrown) {
        console.log(jqXHR.status);
        console.log(jqXHR.statusText);
        console.log(jqXHR.responseJSON);
        if ([400, 500].indexOf(jqXHR.status) !== -1) {
            var errorMsg = '';
            if (typeof jqXHR.responseJSON === 'string') {
                errorMsg = jqXHR.responseJSON;
            } else if (typeof jqXHR.responseJSON === 'object') {
                if (jqXHR.responseJSON.message) {
                    errorMsg = jqXHR.responseJSON.message;
                } else {
                    var values = Object.values(jqXHR.responseJSON);
                    for (value of values) {
                        if (value instanceof Array) errorMsg += value.join(', ');
                        else if (typeof value === 'string') errorMsg += value;
                        errorMsg += '\n';
                    }
                }
            }
            if (!errorMsg) {
                errorMsg = jqXHR.statusText.trim().toUpperCase() || '요청 에러';
            }
            swal({
                type: 'error',
                text: errorMsg,
            });
        }
        if (jqXHR.status === 401) {
            location.href = '/auth/sign-in?redirectUrl=' + location.href;
        } else if (jqXHR.status === 403) {
            location.href = '/auth/error403?redirectUrl=' + location.href;
        } else if (jqXHR.status === 404) {
            // location.href = '/auth/error404';
        } else if (jqXHR.status === 500) {
            // location.href = '/auth/error500';
        }
        if (typeof error === 'function') return error(jqXHR, textStatus, errorThrown);
    };
});

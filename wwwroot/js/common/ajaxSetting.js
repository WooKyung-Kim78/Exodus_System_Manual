$(function () {
    // 모든 AJAX 요청에 위조 방지 토큰을 자동으로 실어 보낸다.
    var token = $('#__AjaxAntiForgeryForm input[name="__RequestVerificationToken"]').val();

    $.ajaxSetup({
        beforeSend: function (xhr, settings) {
            if (token && !/^(GET|HEAD|OPTIONS|TRACE)$/i.test(settings.type)) {
                xhr.setRequestHeader('RequestVerificationToken', token);
            }
        },
        statusCode: {
            401: function () {
                window.location.href = '/auth/sign-in?returnUrl=' + encodeURIComponent(window.location.pathname);
            },
            403: function () {
                window.location.href = '/auth/error403';
            }
        }
    });
});

function getErrorMessage(xhr, fallback) {
    try {
        return xhr.responseJSON && xhr.responseJSON.message
            ? xhr.responseJSON.message
            : (fallback || '요청을 처리하지 못했습니다.');
    } catch (e) {
        return fallback || '요청을 처리하지 못했습니다.';
    }
}

function showToast(text, type) {
    if (typeof $.toast !== 'function') {
        if (type === 'error') console.error(text); else console.log(text);
        return;
    }
    $.toast({ text: text, icon: type, position: 'bottom-right', hideAfter: 3000, loader: false });
}

function toastOk(text) { showToast(text || '저장되었습니다.', 'success'); }
function toastError(text) { showToast(text || '요청을 처리하지 못했습니다.', 'error'); }

// Vue 마운트가 실패하면 v-cloak 이 남아 화면이 통째로 비어 보인다.
// 원인을 감추지 않으면서도 백지 상태는 피하도록, 일정 시간 뒤 강제로 노출하고 콘솔에 남긴다.
setTimeout(function () {
    var stuck = document.querySelectorAll('[v-cloak]');
    if (!stuck.length) return;

    console.error('[app] Vue 마운트 실패로 v-cloak 이 남아 있습니다. 위 콘솔 오류를 확인하세요.', stuck);
    stuck.forEach(function (el) { el.removeAttribute('v-cloak'); });
}, 3000);

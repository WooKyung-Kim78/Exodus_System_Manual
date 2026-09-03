$(function () {
    var $form = $('#loginForm');
    var $btn = $('#loginBtn');
    var $error = $('#loginError');

    $form.on('submit', function (e) {
        e.preventDefault();

        var USER_ID = $('#userId').val();
        var PASSWORD = $('#password').val();

        if (!USER_ID || !PASSWORD) {
            showError('아이디와 비밀번호를 입력하세요.');
            return;
        }

        $btn.attr('data-kt-indicator', 'on').prop('disabled', true);
        $error.addClass('d-none');

        $.ajax({
            url: '/Auth/UserLogin',
            method: 'POST',
            dataType: 'json',
            data: { USER_ID: USER_ID, PASSWORD: PASSWORD }
        })
            .done(function () {
                window.location.href = $('#returnUrl').val() || '/';
            })
            .fail(function (xhr) {
                showError(getErrorMessage(xhr, '로그인에 실패했습니다.'));
                $('#password').val('').focus();
            })
            .always(function () {
                $btn.removeAttr('data-kt-indicator').prop('disabled', false);
            });
    });

    function showError(message) {
        $error.text(message).removeClass('d-none');
    }
});

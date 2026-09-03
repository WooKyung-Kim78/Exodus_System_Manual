new Vue({
    el: '#app',
    data: {
        setting: {
            SYSTEM_NAME: '', SYSTEM_EMAIL: '', SYSTEM_SMTP: '',
            SYSTEM_SMTP_PORT: '587', SYSTEM_SMTP_SECURE: 'STARTTLS',
            SYSTEM_EMAIL_ID: '', SYSTEM_SMTP_SCOPE: 'T',
        },
        password: '',
        hasPassword: false,
        saving: false,
        sending: false,
        testTo: '',
        logs: [],
    },
    computed: {
        testMode: function () { return this.setting.SYSTEM_SMTP_SCOPE === 'T'; },
    },
    mounted: function () {
        this.callSetting();
        this.callLog();
    },
    methods: {
        callSetting: function () {
            var self = this;
            $.get('/admin/setting/mail').done(function (res) {
                self.setting = res.data.setting;
                self.hasPassword = res.data.hasPassword;
            });
        },
        callLog: function () {
            var self = this;
            $.get('/admin/setting/mail/log').done(function (res) { self.logs = res.data.list; });
        },
        save: function () {
            var self = this;
            self.saving = true;
            $.post('/admin/setting/mail', $.extend({}, self.setting, { SYSTEM_EMAIL_PASSWORD: self.password }))
                .done(function () {
                    self.password = '';
                    self.callSetting();
                    toastOk('설정을 저장했습니다.');
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.saving = false; });
        },
        sendTest: function () {
            var self = this;
            if (!self.testTo) { toastError('받는 사람 주소를 입력하세요.'); return; }

            self.sending = true;
            $.post('/admin/setting/mail/test', { to: self.testTo })
                .done(function (res) {
                    toastOk(res.data.testMode
                        ? 'TEST 모드: App_Data/mail-drop 에 저장했습니다.'
                        : '테스트 메일을 발송했습니다.');
                    self.callLog();
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); self.callLog(); })
                .always(function () { self.sending = false; });
        },
        formatDateTime: function (v) {
            if (!v) return '';
            var d = new Date(v);
            return isNaN(d.getTime()) ? '' : d.toLocaleString();
        },
    },
});

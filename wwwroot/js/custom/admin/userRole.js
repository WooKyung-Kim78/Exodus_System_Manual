var SELECTABLE_ROLES = ['ADMIN', 'USER', 'READER'];

new Vue({
    el: '#app',
    data: {
        loading: true,
        list: [],
        keyword: '',
        saving: '',
    },
    mounted: function () {
        this.callList();
    },
    methods: {
        callList: function () {
            var self = this;
            self.loading = true;
            $.get('/admin/user-role/list', { keyword: self.keyword })
                .done(function (res) { self.list = res.data.list; })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.loading = false; });
        },
        // 화면에 없는 구 역할(SUPPORTER)은 실수로 덮어쓰지 않도록 잠근다.
        selectable: function (role) { return SELECTABLE_ROLES.indexOf(role) >= 0; },
        changeRole: function (u, role) {
            var self = this;
            if (role === u.ROLE_NAME) return;

            self.saving = u.USER_ID;
            $.post('/admin/user-role', { USER_ID: u.USER_ID, ROLE_NAME: role })
                .done(function () {
                    u.ROLE_NAME = role;
                    toastOk(u.FULL_NAME + ' 님의 역할을 변경했습니다.');
                })
                .fail(function (xhr) {
                    toastError(getErrorMessage(xhr));
                    self.callList();
                })
                .always(function () { self.saving = ''; });
        },
    },
});

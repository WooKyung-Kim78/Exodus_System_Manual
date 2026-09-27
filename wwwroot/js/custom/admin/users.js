var ROLE_LABEL = { ADMIN: '관리자', USER: '유저', READER: '읽기전용', SUPPORTER: '서포터' };

new Vue({
    el: '#app',
    data: {
        loading: true,
        list: [],
        // 검색으로 목록이 줄어도 드롭다운은 전체 사용자 기준을 유지한다.
        lookup: [],
        keyword: '',
        view: 'USE',
        busy: '',
        form: {},
        isNew: false,
        formError: '',
        saving: false,
        pwForm: {},
        pwError: '',
        pwSaving: false,
    },
    computed: {
        divisions: function () {
            return this.distinct(this.lookup.map(function (u) { return u.DIVISION; }));
        },
        teamOptions: function () {
            return this.distinct(this.lookup.map(function (u) { return u.TEAM; }));
        },
        supervisors: function () {
            var id = this.form.USER_ID;
            return this.lookup.filter(function (u) { return u.USER_ID !== id; });
        },
    },
    created: function () {
        this._modals = {};
    },
    mounted: function () {
        this.callList();
    },
    methods: {
        modal: function (id) {
            if (!this._modals[id]) {
                var el = document.getElementById(id);
                if (!el) return null;
                this._modals[id] = new bootstrap.Modal(el);
            }
            return this._modals[id];
        },
        distinct: function (values) {
            var seen = {};
            values.forEach(function (v) { if (v) seen[v] = true; });
            return Object.keys(seen).sort();
        },
        roleLabel: function (role) { return ROLE_LABEL[role] || role; },
        statusLabel: function (s) { return s === 'Y' ? '승인' : '미승인'; },
        statusClass: function (s) {
            return s === 'Y' ? 'badge badge-light-success' : 'badge badge-light-warning';
        },

        callList: function () {
            var self = this;
            var full = !self.keyword && self.view === 'USE';

            self.loading = true;
            $.get('/admin/user/list', { keyword: self.keyword, view: self.view })
                .done(function (res) {
                    self.list = res.data.list;
                    if (full) self.lookup = res.data.list;
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.loading = false; });
        },

        openForm: function (u) {
            this.formError = '';
            this.isNew = !u;
            this.form = u
                ? {
                    USER_ID: u.USER_ID, FULL_NAME: u.FULL_NAME, EMAIL: u.EMAIL,
                    DIVISION: u.DIVISION, TEAM: u.TEAM,
                    SUPERVISOR_USER_ID: u.SUPERVISOR_USER_ID || null,
                    // 화면은 승인/미승인 두 가지만 쓰므로 예전 차단(N) 값도 미승인으로 모은다.
                    ROLE_NAME: u.ROLE_NAME, AUTHORIZED: u.AUTHORIZED === 'Y' ? 'Y' : 'S', N_PASSWORD: '',
                }
                : {
                    USER_ID: '', FULL_NAME: '', EMAIL: '', DIVISION: '', TEAM: '',
                    SUPERVISOR_USER_ID: null, ROLE_NAME: 'USER', AUTHORIZED: 'Y', N_PASSWORD: '',
                };
            this.modal('userModal').show();
        },
        save: function () {
            var self = this;
            if (!self.form.USER_ID || !self.form.FULL_NAME) {
                self.formError = '아이디와 이름은 필수입니다.';
                return;
            }
            if (self.isNew && !self.form.N_PASSWORD) {
                self.formError = '초기 비밀번호를 입력하세요.';
                return;
            }

            self.saving = true;
            self.formError = '';
            $.post('/admin/user', self.form)
                .done(function () {
                    self.modal('userModal').hide();
                    self.callList();
                    toastOk('저장했습니다.');
                })
                .fail(function (xhr) { self.formError = getErrorMessage(xhr); })
                .always(function () { self.saving = false; });
        },

        openPassword: function (u) {
            this.pwError = '';
            this.pwForm = { USER_ID: u.USER_ID, FULL_NAME: u.FULL_NAME, N_PASSWORD: '', C_PASSWORD: '' };
            this.modal('passwordModal').show();
        },
        savePassword: function () {
            var self = this;
            if (!self.pwForm.N_PASSWORD) {
                self.pwError = '새 비밀번호를 입력하세요.';
                return;
            }
            if (self.pwForm.N_PASSWORD !== self.pwForm.C_PASSWORD) {
                self.pwError = '두 비밀번호가 서로 다릅니다.';
                return;
            }

            self.pwSaving = true;
            self.pwError = '';
            $.post('/admin/user/password', { USER_ID: self.pwForm.USER_ID, N_PASSWORD: self.pwForm.N_PASSWORD })
                .done(function () {
                    self.modal('passwordModal').hide();
                    toastOk('비밀번호를 변경했습니다.');
                })
                .fail(function (xhr) { self.pwError = getErrorMessage(xhr); })
                .always(function () { self.pwSaving = false; });
        },

        setStatus: function (u, authorized) {
            var self = this;
            self.busy = u.USER_ID;
            $.post('/admin/user/authorized', { userId: u.USER_ID, authorized: authorized })
                .done(function () { self.callList(); toastOk('계정 상태를 바꿨습니다.'); })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.busy = ''; });
        },
        remove: function (u) {
            var self = this;
            if (!confirm(u.FULL_NAME + ' (' + u.USER_ID + ') 계정을 삭제합니다.')) return;

            self.busy = u.USER_ID;
            $.ajax({ url: '/admin/user', method: 'DELETE', data: { userId: u.USER_ID } })
                .done(function () { self.callList(); toastOk('삭제했습니다.'); })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.busy = ''; });
        },
        restore: function (u) {
            var self = this;
            if (!confirm(u.FULL_NAME + ' (' + u.USER_ID + ') 계정을 복구합니다. 복구 직후에는 미승인 상태가 됩니다.')) return;

            self.busy = u.USER_ID;
            $.post('/admin/user/restore', { userId: u.USER_ID })
                .done(function () { self.callList(); toastOk('복구했습니다.'); })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.busy = ''; });
        },
    },
});

var LEVEL_LABEL = { 1: '대제목', 2: '중제목', 3: '소제목' };
var LABEL_NAME = { EXODUS: 'Exodus', OEM: 'OEM' };
var COOLING_NAME = { AIR: 'Air', LIQUID: 'Liquid' };

new Vue({
    el: '#app',
    data: {
        loading: true,
        list: [],
        filter: { label: '', cooling: '' },
        teams: [],
        form: {},
        formError: '',
        saving: false,
    },
    created: function () {
        this._modals = {};
    },
    mounted: function () {
        this.callList();
        this.callTeams();
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
        callList: function () {
            var self = this;
            self.loading = true;
            $.get('/admin/section-template/list', { label: self.filter.label, cooling: self.filter.cooling })
                .done(function (res) { self.list = res.data.list; })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.loading = false; });
        },
        callTeams: function () {
            var self = this;
            $.get('/manual/teams').done(function (res) { self.teams = res.data.teams; });
        },
        openForm: function (t) {
            this.formError = '';
            this.form = t
                ? { TPL_ID: t.TPL_ID, LABEL: t.LABEL || '', COOLING: t.COOLING || '',
                    SEC_LEVEL: t.SEC_LEVEL, SEC_NO: t.SEC_NO || '', TITLE: t.TITLE,
                    IS_MANDATORY: t.IS_MANDATORY, ASSIGNED_TEAM: t.ASSIGNED_TEAM || '' }
                : { TPL_ID: null, LABEL: this.filter.label, COOLING: this.filter.cooling,
                    SEC_LEVEL: 1, SEC_NO: '', TITLE: '', IS_MANDATORY: 'Y', ASSIGNED_TEAM: '' };

            this.modal('tplModal').show();
        },
        save: function () {
            var self = this;
            if (!self.form.TITLE) { self.formError = '제목은 필수입니다.'; return; }

            self.saving = true;
            self.formError = '';
            $.post('/admin/section-template', self.form)
                .done(function () {
                    self.modal('tplModal').hide();
                    self.callList();
                    toastOk('저장했습니다.');
                })
                .fail(function (xhr) { self.formError = getErrorMessage(xhr); })
                .always(function () { self.saving = false; });
        },
        remove: function (t) {
            var self = this;
            if (!confirm('"' + t.TITLE + '" 항목을 삭제합니다.\n이미 만들어진 문서의 목차는 그대로 남습니다.')) return;

            $.ajax({ url: '/admin/section-template', method: 'DELETE', data: { tplId: t.TPL_ID } })
                .done(function () { self.callList(); toastOk('삭제했습니다.'); })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); });
        },
        move: function (index, delta) {
            var self = this;
            var target = index + delta;
            if (target < 0 || target >= self.list.length) return;

            var arr = self.list.slice();
            var tmp = arr[index]; arr[index] = arr[target]; arr[target] = tmp;
            self.list = arr;

            var orders = arr.map(function (t, i) { return t.TPL_ID + ':' + (i + 1); }).join(',');
            $.post('/admin/section-template/order', { orders: orders })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); self.callList(); });
        },
        levelLabel: function (lv) { return LEVEL_LABEL[lv] || ''; },
        scopeLabel: function (t) {
            var l = t.LABEL ? LABEL_NAME[t.LABEL] : '모든 Label';
            var c = t.COOLING ? COOLING_NAME[t.COOLING] : '모든 Cooling';
            return l + ' · ' + c;
        },
    },
});

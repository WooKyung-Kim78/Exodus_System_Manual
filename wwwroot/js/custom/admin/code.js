new Vue({
    el: '#app',
    data: {
        loading: true,
        list: [],
        filter: '',
        form: {},
        formError: '',
        saving: false,
        uploading: false,
    },
    computed: {
        categories: function () {
            var seen = {};
            this.list.forEach(function (c) { seen[c.CATEGORY] = true; });
            return Object.keys(seen).sort();
        },
        logoPath: function () {
            var row = this.list.filter(function (c) {
                return c.CATEGORY === 'COVER' && c.CODE === 'LOGO_PATH';
            })[0];
            return row && row.NAME ? row.NAME : '';
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
        callList: function () {
            var self = this;
            self.loading = true;
            // 분류 목록을 유지해야 해서 필터는 화면에서 건다.
            $.get('/admin/code/list')
                .done(function (res) {
                    self.list = self.filter
                        ? res.data.list.filter(function (c) { return c.CATEGORY === self.filter; })
                        : res.data.list;
                    self._all = res.data.list;
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.loading = false; });
        },
        openForm: function (c) {
            this.formError = '';
            this.form = c
                ? { IDX: c.IDX, CATEGORY: c.CATEGORY, CODE: c.CODE, NAME: c.NAME, ORDER_NUM: c.ORDER_NUM }
                : { IDX: null, CATEGORY: this.filter || '', CODE: '', NAME: '', ORDER_NUM: 0 };
            this.modal('codeModal').show();
        },
        save: function () {
            var self = this;
            if (!self.form.CATEGORY || !self.form.CODE) {
                self.formError = '분류와 코드는 필수입니다.';
                return;
            }

            self.saving = true;
            self.formError = '';
            $.post('/admin/code', self.form)
                .done(function () {
                    self.modal('codeModal').hide();
                    self.callList();
                    toastOk('저장했습니다.');
                })
                .fail(function (xhr) { self.formError = getErrorMessage(xhr); })
                .always(function () { self.saving = false; });
        },
        remove: function (c) {
            var self = this;
            if (!confirm(c.CATEGORY + ' / ' + c.CODE + ' 코드를 삭제합니다.')) return;

            $.ajax({ url: '/admin/code', method: 'DELETE', data: { idx: c.IDX } })
                .done(function () { self.callList(); toastOk('삭제했습니다.'); })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); });
        },
        pickLogo: function () {
            var self = this;
            var input = document.createElement('input');
            input.type = 'file';
            input.accept = 'image/png,image/jpeg,image/gif,image/webp';
            input.addEventListener('change', function () {
                if (input.files && input.files[0]) self.uploadLogo(input.files[0]);
            });
            input.click();
        },
        uploadLogo: function (file) {
            var self = this;
            var fd = new FormData();
            fd.append('file', file);
            fd.append('__RequestVerificationToken', self.token());

            self.uploading = true;
            $.ajax({ url: '/admin/code/logo', method: 'POST', data: fd, processData: false, contentType: false })
                .done(function () { self.callList(); toastOk('로고를 등록했습니다.'); })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.uploading = false; });
        },
        token: function () {
            return $('#__AjaxAntiForgeryForm input[name="__RequestVerificationToken"]').val();
        },
    },
});

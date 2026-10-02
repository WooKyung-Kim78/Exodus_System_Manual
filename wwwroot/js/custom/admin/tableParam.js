var FN_TOOLBAR = [
    'undo', 'redo', '|', 'fontColor', 'fontBackgroundColor', '|',
    'bold', 'italic', 'underline', 'strikethrough', 'subscript', 'superscript', 'removeFormat', '|',
    'bulletedList', 'numberedList',
];

function htmlText(html) {
    var doc = new DOMParser().parseFromString(String(html || ''), 'text/html');
    return (doc.body.textContent || '').replace(/\s+/g, ' ').trim();
}

new Vue({
    el: '#app',
    data: {
        loading: true,
        list: [],
        keyword: '',
        form: {},
        formError: '',
        saving: false,
        ckReady: typeof window.createBlockEditor === 'function',
        editorLoading: false,
    },
    computed: {
        filtered: function () {
            var k = this.keyword.toLowerCase();
            if (!k) return this.list;
            return this.list.filter(function (p) {
                return p.TITLE.toLowerCase().indexOf(k) >= 0 || htmlText(p.FUNC_HTML).toLowerCase().indexOf(k) >= 0;
            });
        },
        titles: function () {
            var seen = {};
            this.list.forEach(function (p) { seen[p.TITLE] = true; });
            return Object.keys(seen);
        },
    },
    created: function () {
        this._modals = {};
        this._editor = null;
        this._allowClose = false;
    },
    mounted: function () {
        var self = this;
        self.callList();

        var el = document.getElementById('paramModal');
        // CKEditor 패널이 body 에 붙어 바깥 클릭으로 오인될 수 있다. 저장·취소로만 닫는다.
        el.addEventListener('hide.bs.modal', function (e) {
            if (!self._allowClose) e.preventDefault();
        });
        el.addEventListener('hidden.bs.modal', function () {
            self._allowClose = false;
            self.destroyEditor();
        });
        if (!self.ckReady) {
            window.addEventListener('ckeditor-ready', function () {
                self.ckReady = true;
                if (el.classList.contains('show')) self.createEditor();
            });
        }
    },
    methods: {
        modal: function (id) {
            if (!this._modals[id]) {
                var el = document.getElementById(id);
                if (!el) return null;
                // 포커스 트랩을 켜면 body 에 열리는 글자색 패널이 포커스를 빼앗겨 바로 닫힌다.
                this._modals[id] = new bootstrap.Modal(el, { focus: false, backdrop: 'static', keyboard: false });
            }
            return this._modals[id];
        },
        callList: function () {
            var self = this;
            self.loading = true;
            $.get('/admin/table-param/list')
                .done(function (res) { self.list = res.data.list; })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.loading = false; });
        },
        openForm: function (p) {
            this.formError = '';
            this.form = p
                ? { IDX: p.IDX, TITLE: p.TITLE, FUNC_HTML: p.FUNC_HTML, ORDER_NUM: p.ORDER_NUM }
                : { IDX: null, TITLE: '', FUNC_HTML: '', ORDER_NUM: 1 };
            this.modal('paramModal').show();
            this.editorLoading = true;
            this.$nextTick(this.createEditor);
        },
        closeForm: function () {
            this._allowClose = true;
            this.modal('paramModal').hide();
        },
        createEditor: function () {
            var self = this;
            if (!self.ckReady || self._editor) return;
            var host = document.getElementById('paramFuncEditor');
            if (!host) return;

            self._editor = 'pending';
            window.createBlockEditor(host, self.form.FUNC_HTML, {
                toolbar: FN_TOOLBAR,
                onChange: function (html) { self.form.FUNC_HTML = html; },
            }).then(function (editor) {
                if (self._editor !== 'pending') { editor.destroy(); return; }
                self._editor = editor;
                self.editorLoading = false;
            }).catch(function () {
                self._editor = null;
                self.editorLoading = false;
                toastError('편집기를 불러오지 못했습니다.');
            });
        },
        destroyEditor: function () {
            if (this._editor && this._editor.destroy) this._editor.destroy();
            this._editor = null;
            this.editorLoading = false;
        },
        save: function () {
            var self = this;
            if (self._editor && self._editor.getData) self.form.FUNC_HTML = self._editor.getData();
            if (!$.trim(self.form.TITLE) || !htmlText(self.form.FUNC_HTML)) {
                self.formError = 'Title 과 Function 은 필수입니다.';
                return;
            }

            self.saving = true;
            self.formError = '';
            $.post('/admin/table-param', self.form)
                .done(function () {
                    self.closeForm();
                    self.callList();
                    toastOk('저장했습니다.');
                })
                .fail(function (xhr) { self.formError = getErrorMessage(xhr); })
                .always(function () { self.saving = false; });
        },
        remove: function (p) {
            var self = this;
            if (!confirm('"' + p.TITLE + '" 항목을 삭제합니다.')) return;

            $.ajax({ url: '/admin/table-param', method: 'DELETE', data: { idx: p.IDX } })
                .done(function () { self.callList(); toastOk('삭제했습니다.'); })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); });
        },
    },
});

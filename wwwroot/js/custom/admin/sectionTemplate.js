var LEVEL_LABEL = { 1: '대제목', 2: '중제목', 3: '소제목' };
var LABEL_NAME = { EXODUS: 'Exodus', OEM: 'OEM' };
var COOLING_NAME = { AIR: 'Air', LIQUID: 'Liquid' };
var ALIGN_LABEL = { LEFT: '왼쪽', CENTER: '가운데', RIGHT: '오른쪽' };
var ALIGN_CSS = { LEFT: 'left', CENTER: 'center', RIGHT: 'right' };

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
        ckReady: typeof window.createBlockEditor === 'function',
        contentEditorLoading: false,
    },
    computed: {
        isPageBreak: function () { return this.form.SEC_TYPE === 'PAGEBREAK'; },
    },
    watch: {
        // 종류를 바꾸면 내용 편집기 영역이 통째로 사라졌다 다시 생기므로 인스턴스도 맞춰 준다.
        'form.SEC_TYPE': function (type) {
            var self = this;
            self.destroyContentEditor();
            if (type === 'PAGEBREAK') return;
            self.contentEditorLoading = true;
            self.$nextTick(self.createContentEditor);
        },
    },
    created: function () {
        this._modals = {};
        this._contentEditor = null;
        this._allowClose = false;
    },
    mounted: function () {
        this.callList();
        this.callTeams();
        var self = this;
        var el = document.getElementById('tplModal');
        // CKEditor 는 풀선·파일 선택창을 body 에 붙여 모달 밖 클릭으로 오인되는 경로가 여러 개다.
        // 원인을 가리지 않고 저장·취소 외의 닫힘을 모두 막는다.
        el.addEventListener('hide.bs.modal', function (e) {
            if (!self._allowClose) e.preventDefault();
        });
        el.addEventListener('hidden.bs.modal', function () {
            self._allowClose = false;
            self.destroyContentEditor();
        });
        if (!this.ckReady) {
            window.addEventListener('ckeditor-ready', function () {
                self.ckReady = true;
                if (el.classList.contains('show')) self.createContentEditor();
            });
        }
    },
    methods: {
        modal: function (id) {
            if (!this._modals[id]) {
                var el = document.getElementById(id);
                if (!el) return null;
                // 포커스 트랩을 켜면 모달 밖(body)에 열리는 CKEditor 속성 창이 포커스를 뺏겨 바로 닫힌다.
                // 배경 클릭·ESC 로도 닫지 않는다. 작성하던 내용이 통째로 날아가기 때문이다.
                this._modals[id] = new bootstrap.Modal(el, { focus: false, backdrop: 'static', keyboard: false });
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
                    IS_MANDATORY: t.IS_MANDATORY, ASSIGNED_TEAM: t.ASSIGNED_TEAM || '',
                    CONTENT_HTML: t.CONTENT_HTML || '', TITLE_ALIGN: t.TITLE_ALIGN || 'LEFT',
                    SEC_TYPE: t.SEC_TYPE || 'NORMAL', SHOW_IN_TOC: t.SHOW_IN_TOC || 'Y',
                    TITLE_UNDERLINE: t.TITLE_UNDERLINE || 'N' }
                : { TPL_ID: null, LABEL: this.filter.label, COOLING: this.filter.cooling,
                    SEC_LEVEL: 1, SEC_NO: '', TITLE: '', IS_MANDATORY: 'Y', ASSIGNED_TEAM: '',
                    CONTENT_HTML: '', TITLE_ALIGN: 'LEFT', SEC_TYPE: 'NORMAL',
                    SHOW_IN_TOC: 'Y', TITLE_UNDERLINE: 'N' };

            this.modal('tplModal').show();
            if (this.isPageBreak) return;
            this.contentEditorLoading = true;
            this.$nextTick(this.createContentEditor);
        },
        closeForm: function () {
            this._allowClose = true;
            this.modal('tplModal').hide();
        },
        createContentEditor: function () {
            var self = this;
            if (!self.ckReady || self._contentEditor) return;
            var host = document.getElementById('tplContentEditor');
            if (!host) return;
            self._contentEditor = 'pending';
            window.createBlockEditor(host, self.form.CONTENT_HTML, {
                uploadUrl: '/admin/section-template/image',
                uploadHeaders: { RequestVerificationToken: $('#__AjaxAntiForgeryForm input[name="__RequestVerificationToken"]').val() },
                onChange: function (html) { self.form.CONTENT_HTML = html; },
            }).then(function (editor) {
                // 만드는 사이에 종류를 바꿔 영역이 사라졌으면 그대로 버린다.
                if (self._contentEditor !== 'pending') { editor.destroy(); return; }
                self._contentEditor = editor;
                self.contentEditorLoading = false;
            }).catch(function () {
                self._contentEditor = null;
                self.contentEditorLoading = false;
                toastError('내용 편집기를 불러오지 못했습니다.');
            });
        },
        destroyContentEditor: function () {
            if (this._contentEditor && this._contentEditor.destroy) this._contentEditor.destroy();
            this._contentEditor = null;
            this.contentEditorLoading = false;
        },
        save: function () {
            var self = this;
            // 페이지 나눔은 입력란이 없어 제목을 여기서 채운다. 값은 서버가 다시 고정한다.
            if (self.isPageBreak) self.form.TITLE = '페이지 나눔';
            if (!self.form.TITLE) { self.formError = '제목은 필수입니다.'; return; }
            if (!self.isPageBreak && self._contentEditor && self._contentEditor.getData) {
                self.form.CONTENT_HTML = self._contentEditor.getData();
            }

            self.saving = true;
            self.formError = '';
            $.post('/admin/section-template', self.form)
                .done(function () {
                    self.closeForm();
                    self.callList();
                    toastOk('저장했습니다.');
                })
                .fail(function (xhr) { self.formError = getErrorMessage(xhr); })
                .always(function () { self.saving = false; });
        },
        remove: function (t) {
            var self = this;
            var name = t.SEC_TYPE === 'PAGEBREAK' ? '페이지 나눔' : t.TITLE;
            if (!confirm('"' + name + '" 항목을 삭제합니다.\n이미 만들어진 문서의 목차는 그대로 남습니다.')) return;

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
        alignLabel: function (a) { return ALIGN_LABEL[a] || ALIGN_LABEL.LEFT; },
        alignCss: function (a) { return ALIGN_CSS[a] || 'left'; },
        scopeLabel: function (t) {
            var l = t.LABEL ? LABEL_NAME[t.LABEL] : '모든 Label';
            var c = t.COOLING ? COOLING_NAME[t.COOLING] : '모든 Cooling';
            return l + ' · ' + c;
        },
    },
});

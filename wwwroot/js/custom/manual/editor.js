var STATUS_LABEL = { DRAFT: '작성중', REVIEW: '결재요청', APPROVED: '결재완료', PUBLISHED: '발행', OBSOLETE: '폐기' };
var STATUS_CLASS = {
    DRAFT: 'badge badge-light-secondary',
    REVIEW: 'badge badge-light-warning',
    APPROVED: 'badge badge-light-primary',
    PUBLISHED: 'badge badge-light-success',
    OBSOLETE: 'badge badge-light-dark',
};
var LEVEL_LABEL = { 1: '대제목', 2: '중제목', 3: '소제목' };
var ACTION_LABEL = {
    CREATE: '추가', UPDATE: '수정', DELETE: '삭제',
    REORDER: '순서변경', MOVE: '이동', RESIZE: '크기변경',
    RESTORE: '복원', ASSIGN: '담당변경',
};
var ACTION_CLASS = {
    CREATE: 'badge badge-light-success fs-9',
    UPDATE: 'badge badge-light-primary fs-9',
    DELETE: 'badge badge-light-danger fs-9',
};
var FONT_STACK = {
    ARIAL: 'Arial, Helvetica, sans-serif',
    CALIBRI: "Calibri, 'Segoe UI', sans-serif",
    VERDANA: 'Verdana, Geneva, sans-serif',
    TAHOMA: 'Tahoma, Geneva, sans-serif',
    GEORGIA: "Georgia, 'Times New Roman', serif",
    TIMES: "'Times New Roman', Times, serif",
};
var DEFAULT_HEADING_STYLE = {
    1: { size: 18, color: '#181c32', bold: true, underline: false },
    2: { size: 15, color: '#181c32', bold: true, underline: false },
    3: { size: 13, color: '#3f4254', bold: true, underline: false },
};

new Vue({
    el: '#app',
    data: {
        mid: document.getElementById('app').dataset.mid,
        loading: true,
        header: null,
        sections: [],
        blocks: [],
        access: null,
        teams: [],
        candidates: [],
        activeSecId: null,
        saveState: '',
        secForm: {},
        secError: '',
        savingSection: false,
        secStyleOn: false,
        secStyle: { size: 18, color: '#181c32', bold: true, underline: false },
        templateOptions: [],
        templateLoading: false,
        addingTpl: null,
        history: [],
        historyLoading: false,
        headingStyle: JSON.parse(JSON.stringify(DEFAULT_HEADING_STYLE)),
        bodyFont: 'ARIAL',
        bodyLineHeight: 1,
        bodyLetterSpacing: 0,
        ckReady: typeof window.createBlockEditor === 'function',
    },
    computed: {
        canEdit: function () { return this.access && this.access.CAN_EDIT === 'Y'; },
        // 목차에 팀이 지정되면 그 팀만 내용을 고칠 수 있다. 판정은 서버가 한다.
        canEditActive: function () {
            return this.canEdit && !!this.activeSection && this.activeSection.CAN_EDIT_SEC === 'Y';
        },
        secFormCss: function () {
            var base = this.headingStyle[this.secForm.SEC_LEVEL] || DEFAULT_HEADING_STYLE[1];
            return this.toCss(this.secStyleOn ? this.secStyle : base);
        },
        activeSection: function () {
            var self = this;
            return this.sections.filter(function (s) { return s.SEC_ID === self.activeSecId; })[0] || null;
        },
        activeBlocks: function () {
            var self = this;
            return this.blocks
                .filter(function (b) { return b.SEC_ID === self.activeSecId; })
                .sort(function (a, b) { return a.ORDER_NUM - b.ORDER_NUM; });
        },
    },
    watch: {
        activeBlocks: function () { this.$nextTick(this.syncEditors); },
        // 개별 지정을 켜기 전까지는 선택한 단계의 공통값을 따라가게 둔다.
        'secForm.SEC_LEVEL': function (lv) {
            if (!this.secStyleOn) this.secStyle = $.extend({}, this.levelStyle(lv));
        },
    },
    created: function () {
        // CKEditor 인스턴스는 객체 그래프가 커서 Vue 반응형으로 만들면 안 된다.
        // data 가 아닌 인스턴스 속성으로 두면 반응형 변환을 피할 수 있다.
        this._editors = {};
        this._modals = {};
    },
    mounted: function () {
        var self = this;
        if (!self.ckReady) {
            window.addEventListener('ckeditor-ready', function () {
                self.ckReady = true;
                self.$nextTick(self.syncEditors);
            });
        }
        self.callData();
        self.callTeams();
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

        /* ---------- 데이터 ---------- */
        callData: function () {
            var self = this;
            $.get('/editor/data', { mid: self.mid })
                .done(function (res) {
                    self.header = res.data.header;
                    self.sections = res.data.sections;
                    self.blocks = res.data.blocks;
                    self.access = res.data.access;

                    if (self.header && self.header.HEADING_STYLE_JSON) {
                        try { self.headingStyle = $.extend(true, {}, DEFAULT_HEADING_STYLE, JSON.parse(self.header.HEADING_STYLE_JSON)); }
                        catch (e) { /* 저장된 값이 깨졌으면 기본값을 쓴다 */ }
                    }
                    if (self.header) {
                        self.bodyFont = self.header.BODY_FONT || 'ARIAL';
                        self.bodyLineHeight = Number(self.header.BODY_LINE_HEIGHT) || 1;
                        self.bodyLetterSpacing = Number(self.header.BODY_LETTER_SPACING) || 0;
                        self.applyBodyStyle();
                    }
                    if (!self.activeSecId && self.sections.length) {
                        // 문서 정보 화면에서 특정 목차의 '본문' 버튼으로 들어온 경우
                        var wanted = Number(document.getElementById('app').dataset.secId);
                        var found = wanted && self.sections.filter(function (s) { return s.SEC_ID === wanted; })[0];
                        self.activeSecId = found ? found.SEC_ID : self.sections[0].SEC_ID;
                    }
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () {
                    self.loading = false;
                    self.$nextTick(self.syncEditors);
                });
        },
        callTeams: function () {
            var self = this;
            $.get('/manual/teams').done(function (res) { self.teams = res.data.teams; });
        },

        /* ---------- 목차 ---------- */
        selectSection: function (s) {
            this.destroyEditors();
            this.activeSecId = s.SEC_ID;
        },
        openSection: function (s) {
            this.secError = '';
            this.secForm = s
                ? { SEC_ID: s.SEC_ID, TITLE: s.TITLE, SEC_LEVEL: s.SEC_LEVEL, SEC_NO: s.SEC_NO,
                    ASSIGNED_TEAM: s.ASSIGNED_TEAM }
                : { SEC_ID: null, TITLE: '', SEC_LEVEL: 1, SEC_NO: '', ASSIGNED_TEAM: null };

            var own = s ? this.parseStyle(s.STYLE_JSON) : null;
            this.secStyleOn = !!own;
            this.secStyle = $.extend({}, this.levelStyle(this.secForm.SEC_LEVEL), own || {});

            this.modal('sectionModal').show();
        },
        loadCandidates: function (team) {
            var self = this;
            $.get('/manual/users', { team: team }).done(function (res) { self.candidates = res.data.users; });
        },
        saveSection: function () {
            var self = this;
            if (!self.secForm.TITLE) { self.secError = '제목은 필수입니다.'; return; }

            self.savingSection = true;
            self.secError = '';
            var payload = $.extend({ M_ID: self.mid }, self.secForm, {
                STYLE_JSON: self.secStyleOn ? JSON.stringify(self.secStyle) : '',
            });
            $.post('/editor/section', payload)
                .done(function (res) {
                    self.modal('sectionModal').hide();
                    var newId = Number(res.data.SEC_ID);
                    self.callData();
                    if (!self.secForm.SEC_ID) self.activeSecId = newId;
                    toastOk('목차를 저장했습니다.');
                })
                .fail(function (xhr) { self.secError = getErrorMessage(xhr); })
                .always(function () { self.savingSection = false; });
        },
        removeSection: function () {
            var self = this;
            var s = self.activeSection;
            if (!s || !confirm('"' + s.TITLE + '" 목차를 삭제합니다.\n안에 작성된 내용도 함께 삭제됩니다.')) return;

            $.ajax({ url: '/editor/section', method: 'DELETE', data: { secId: s.SEC_ID, mid: self.mid } })
                .done(function () {
                    self.destroyEditors();
                    self.activeSecId = null;
                    self.callData();
                    toastOk('삭제했습니다.');
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); });
        },
        moveSection: function (delta) {
            var self = this;
            var idx = self.sections.findIndex(function (s) { return s.SEC_ID === self.activeSecId; });
            var target = idx + delta;
            if (idx < 0 || target < 0 || target >= self.sections.length) return;

            var arr = self.sections.slice();
            var tmp = arr[idx]; arr[idx] = arr[target]; arr[target] = tmp;
            self.sections = arr;

            var orders = arr.map(function (s, i) { return s.SEC_ID + ':' + (i + 1); }).join(',');
            $.post('/editor/section/order', { mid: self.mid, orders: orders })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); self.callData(); });
        },

        /* ---------- 수정 이력 ---------- */
        openHistory: function () {
            var self = this;
            if (!self.activeSecId) return;

            self.modal('historyModal').show();
            self.historyLoading = true;
            self.history = [];
            $.get('/editor/section/history', { mid: self.mid, secId: self.activeSecId })
                .done(function (res) { self.history = res.data.list; })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.historyLoading = false; });
        },
        actionLabel: function (a) { return ACTION_LABEL[a] || a; },
        actionClass: function (a) { return ACTION_CLASS[a] || 'badge badge-light fs-9'; },
        historyTarget: function (h) {
            if (h.FIELD_NAME === 'SECTION') return '목차';
            if (h.FIELD_NAME === 'TITLE') return '목차 제목';
            if (h.FIELD_NAME === 'SECTION_ORDER') return '목차 순서';
            if (h.AFTER_VALUE === 'IMAGE') return '이미지 블록';
            if (h.AFTER_VALUE === 'TEXT') return '텍스트 블록';
            return h.ELE_ID ? '블록' : (h.FIELD_NAME || '');
        },
        formatDateTime: function (value) {
            if (!value) return '';
            var d = new Date(value);
            if (isNaN(d.getTime())) return '';
            var pad = function (n) { return (n < 10 ? '0' : '') + n; };
            return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate()) +
                   ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes());
        },

        /* ---------- 템플릿 ---------- */
        openTemplate: function () {
            var self = this;
            self.modal('templateModal').show();
            self.templateLoading = true;
            $.get('/editor/template-options', { mid: self.mid })
                .done(function (res) { self.templateOptions = res.data.list; })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.templateLoading = false; });
        },
        addFromTemplate: function (t) {
            var self = this;
            self.addingTpl = t.TPL_ID;
            $.post('/editor/template-section', { mid: self.mid, tplId: t.TPL_ID })
                .done(function (res) {
                    t.IS_ADDED = 'Y';
                    self.callData();
                    self.activeSecId = Number(res.data.SEC_ID);
                    toastOk('"' + t.TITLE + '" 목차를 추가했습니다.');
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.addingTpl = null; });
        },

        /* ---------- 본문 블록 ---------- */
        addBlock: function (type) {
            var self = this;
            var order = self.activeBlocks.length + 1;

            $.post('/editor/block', {
                M_ID: self.mid, SEC_ID: self.activeSecId, ELE_TYPE: type,
                ORDER_NUM: order, WIDTH: type === 'IMAGE' ? 100 : 0, HEIGHT: 0,
                CONTENT_HTML: type === 'TEXT' ? '<p></p>' : null,
            })
                .done(function (res) { self.blocks.push(res.data.block); })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); });
        },
        pickImage: function () {
            var self = this;
            // 숨겨진 input 을 마크업에 두면 v-if 안쪽이라 마운트 시점에 없다. 필요할 때 만든다.
            var input = document.createElement('input');
            input.type = 'file';
            input.accept = 'image/png,image/jpeg,image/gif,image/webp';
            input.addEventListener('change', function () {
                if (input.files && input.files[0]) self.uploadImage(input.files[0]);
            });
            input.click();
        },
        uploadImage: function (file) {
            var self = this;
            var fd = new FormData();
            fd.append('mid', self.mid);
            fd.append('file', file);
            fd.append('__RequestVerificationToken', self.token());

            $.ajax({ url: '/editor/image', method: 'POST', data: fd, processData: false, contentType: false })
                .done(function (res) {
                    $.post('/editor/block', {
                        M_ID: self.mid, SEC_ID: self.activeSecId, ELE_TYPE: 'IMAGE',
                        ORDER_NUM: self.activeBlocks.length + 1, WIDTH: 100, HEIGHT: 0,
                        IMAGE_PATH: res.data.path, CAPTION: '',
                    }).done(function (r2) { self.blocks.push(r2.data.block); });
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); });
        },
        moveBlock: function (index, delta) {
            var self = this;
            var arr = self.activeBlocks.slice();
            var target = index + delta;
            if (target < 0 || target >= arr.length) return;

            var tmp = arr[index]; arr[index] = arr[target]; arr[target] = tmp;
            arr.forEach(function (b, i) { b.ORDER_NUM = i + 1; });

            self.destroyEditors();
            self.blocks = self.blocks.slice();

            var orders = arr.map(function (b) { return b.ELE_ID + ':' + b.ORDER_NUM; }).join(',');
            $.post('/editor/block/order', { M_ID: self.mid, ORDERS: orders })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); self.callData(); });
        },
        removeBlock: function (b) {
            var self = this;
            if (!confirm('이 블록을 삭제합니다.')) return;

            $.ajax({ url: '/editor/block', method: 'DELETE', data: { eleId: b.ELE_ID, mid: self.mid } })
                .done(function () {
                    self.destroyEditor(b.ELE_ID);
                    self.blocks = self.blocks.filter(function (x) { return x.ELE_ID !== b.ELE_ID; });
                    toastOk('삭제했습니다.');
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); });
        },
        saveBlock: function (b) {
            var self = this;
            self.saveState = '저장 중...';

            $.post('/editor/block', {
                ELE_ID: b.ELE_ID, M_ID: self.mid, SEC_ID: b.SEC_ID, ELE_TYPE: b.ELE_TYPE,
                ORDER_NUM: b.ORDER_NUM, WIDTH: b.WIDTH, HEIGHT: b.HEIGHT,
                CONTENT_HTML: b.CONTENT_HTML, IMAGE_PATH: b.IMAGE_PATH,
                CAPTION: b.CAPTION, STYLE_JSON: b.STYLE_JSON, ROW_VER: b.ROW_VER,
            })
                .done(function (res) {
                    if (res.data.block) b.ROW_VER = res.data.block.ROW_VER;
                    self.saveState = '저장됨';
                    setTimeout(function () { self.saveState = ''; }, 1500);
                })
                .fail(function (xhr) {
                    self.saveState = '저장 실패';
                    toastError(getErrorMessage(xhr));
                    if (xhr.status === 409) self.callData();
                });
        },

        /* ---------- CKEditor 연결 ---------- */
        syncEditors: function () {
            var self = this;
            if (!self.ckReady) return;

            self.activeBlocks.forEach(function (b) {
                if (b.ELE_TYPE !== 'TEXT' || self._editors[b.ELE_ID]) return;

                var host = document.getElementById('ck-' + b.ELE_ID);
                if (!host) return;

                self._editors[b.ELE_ID] = 'pending';
                window.createBlockEditor(host, b.CONTENT_HTML, {
                    readOnly: !self.canEditActive,
                    onBlur: function (html) {
                        if (html === b.CONTENT_HTML) return;
                        b.CONTENT_HTML = html;
                        self.saveBlock(b);
                    },
                }).then(function (editor) {
                    self._editors[b.ELE_ID] = editor;
                }).catch(function (err) {
                    delete self._editors[b.ELE_ID];
                    console.error('CKEditor 초기화 실패', err);
                    toastError('편집기를 불러오지 못했습니다.');
                });
            });
        },
        destroyEditor: function (id) {
            var ed = this._editors[id];
            if (ed && ed !== 'pending' && ed.destroy) ed.destroy();
            delete this._editors[id];
        },
        destroyEditors: function () {
            var self = this;
            Object.keys(self._editors).forEach(function (id) { self.destroyEditor(id); });
        },

        /* ---------- 제목 스타일 ---------- */
        /* ---------- 문서 스타일 ---------- */
        // 지정은 문서 정보 화면에서 하고, 여기서는 적용만 한다.
        applyBodyStyle: function () {
            var root = document.documentElement;
            root.style.setProperty('--doc-font', FONT_STACK[this.bodyFont] || FONT_STACK.ARIAL);
            root.style.setProperty('--doc-line-height', String(this.bodyLineHeight));
            root.style.setProperty('--doc-letter-spacing', this.bodyLetterSpacing + 'px');
        },

        token: function () {
            return $('#__AjaxAntiForgeryForm input[name="__RequestVerificationToken"]').val();
        },
        statusLabel: function (s) { return STATUS_LABEL[s] || s; },
        statusClass: function (s) { return STATUS_CLASS[s] || 'badge badge-light'; },
        levelLabel: function (lv) { return LEVEL_LABEL[lv] || ''; },
        levelStyle: function (lv) {
            return $.extend({}, DEFAULT_HEADING_STYLE[lv] || DEFAULT_HEADING_STYLE[1], this.headingStyle[lv] || {});
        },
        parseStyle: function (json) {
            if (!json) return null;
            try { return JSON.parse(json); }
            catch (e) { return null; }
        },
        toCss: function (s) {
            return {
                fontSize: s.size + 'pt',
                color: s.color,
                fontWeight: s.bold ? 700 : 400,
                textDecoration: s.underline ? 'underline' : 'none',
            };
        },
        headingCss: function (lv) {
            return this.toCss(this.levelStyle(lv));
        },
        // 공통 스타일 위에 목차가 가진 값만 덮어쓴다.
        sectionCss: function (s) {
            return this.toCss($.extend({}, this.levelStyle(s.SEC_LEVEL), this.parseStyle(s.STYLE_JSON) || {}));
        },
    },
});

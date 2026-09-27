var STATUS_LABEL = {
    DRAFT: '작성중', REVIEW: '결재요청', APPROVED: '결재완료', PUBLISHED: '발행', OBSOLETE: '폐기',
};
var STATUS_CLASS = {
    DRAFT: 'badge badge-light-secondary',
    REVIEW: 'badge badge-light-warning',
    APPROVED: 'badge badge-light-primary',
    PUBLISHED: 'badge badge-light-success',
    OBSOLETE: 'badge badge-light-dark',
};
var SEC_STATUS_LABEL = { EMPTY: '미작성', WRITING: '작성중', DONE: '작성완료' };
var LEVEL_LABEL = { 1: '대제목', 2: '중제목', 3: '소제목' };
var FONT_STACK = {
    ARIAL: 'Arial, Helvetica, sans-serif',
    CARLITO: "Carlito, 'Malgun Gothic', sans-serif",
    VERDANA: 'Verdana, Geneva, sans-serif',
    TAHOMA: 'Tahoma, Geneva, sans-serif',
    GEORGIA: "Georgia, 'Times New Roman', serif",
    TIMES: "'Times New Roman', Times, serif",
};
// 제목 기본 스타일은 서버(HeadingStyle.Defaults)가 페이지에 넣어 준다.
var DEFAULT_HEADING_STYLE = window.HEADING_DEFAULTS || {};var SEC_STATUS_CLASS = {
    EMPTY: 'badge badge-light fs-9',
    WRITING: 'badge badge-light-warning fs-9',
    DONE: 'badge badge-light-success fs-9',
};

function formatDateValue(value) {
    if (!value) return '';
    var d = new Date(value);
    if (isNaN(d.getTime())) return '';
    var pad = function (n) { return (n < 10 ? '0' : '') + n; };
    return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate());
}

function formatDateTimeValue(value) {
    if (!value) return '';
    var d = new Date(value);
    if (isNaN(d.getTime())) return '';
    var pad = function (n) { return (n < 10 ? '0' : '') + n; };
    return formatDateValue(value) + ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes());
}

new Vue({
    el: '#app',
    data: {
        mid: document.getElementById('app').dataset.mid,
        loading: true,
        header: null,
        sections: [],
        access: null,
        savingHeader: false,
        specLoading: false,
        specHtml: '',
        specMessage: '',
        uploadingCover: false,
        teams: [],
        secForm: {},
        secError: '',
        secLoading: false,
        savingSection: false,
        templateOptions: [],
        templateLoading: false,
        addingTpl: null,
        addingPageBreak: false,
        headingStyle: JSON.parse(JSON.stringify(DEFAULT_HEADING_STYLE)),
        bodyFont: 'CARLITO',
        bodyFontSize: 12,
        bodyLineHeight: 1.2,
        bodyLetterSpacing: 0,
        notifyMemo: '',
        notifyOnlyAssigned: false,
        notifyTargetsAll: [],
        notifyTestMode: false,
        notifyError: '',
        sendingNotify: false,
    },
    computed: {
        canEdit: function () { return this.access && this.access.CAN_EDIT === 'Y'; },
        bodyCss: function () {
            return {
                fontFamily: FONT_STACK[this.bodyFont] || FONT_STACK.CARLITO,
                fontSize: this.bodyFontSize + 'pt',
                lineHeight: String(this.bodyLineHeight),
                letterSpacing: this.bodyLetterSpacing + 'px',
            };
        },
        notifyTargets: function () {
            var self = this;
            return self.notifyTargetsAll.filter(function (r) {
                if (!r.EMAIL_ADDRESS) return false;
                return !self.notifyOnlyAssigned || r.SECTION_CNT > 0;
            });
        },
    },
    mounted: function () {
        this.callData();
        this.callTeams();
    },
    methods: {
        // 모달 마크업이 v-if 안에 있어 데이터를 다시 불러올 때마다 DOM 이 새로 만들어진다.
        // 인스턴스를 캐시하면 떨어져 나간 예전 요소가 열려 직전 내용이 그대로 보인다.
        modal: function (id) {
            var el = document.getElementById(id);
            if (!el) return null;
            return bootstrap.Modal.getOrCreateInstance(el);
        },
        callData: function () {
            var self = this;
            self.loading = true;
            $.get('/manual/find', { mid: self.mid })
                .done(function (res) {
                    self.header = res.data.header;
                    self.sections = res.data.sections;
                    self.access = res.data.access;

                    if (self.header.HEADING_STYLE_JSON) {
                        try { self.headingStyle = $.extend(true, {}, DEFAULT_HEADING_STYLE, JSON.parse(self.header.HEADING_STYLE_JSON)); }
                        catch (e) { /* 저장된 값이 깨졌으면 기본값을 쓴다 */ }
                    }
                    self.bodyFont = FONT_STACK[self.header.BODY_FONT] ? self.header.BODY_FONT : 'CARLITO';
                    self.bodyFontSize = Number(self.header.BODY_FONT_SIZE) || 12;
                    self.bodyLineHeight = Number(self.header.BODY_LINE_HEIGHT) || 1.2;
                    self.bodyLetterSpacing = Number(self.header.BODY_LETTER_SPACING) || 0;
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.loading = false; });
        },

        saveHeader: function () {
            var self = this;
            self.savingHeader = true;
            $.post('/manual/header', {
                M_ID: self.mid,
                MODEL_NAME: self.header.MODEL_NAME,
                JOB_NUMBER: self.header.JOB_NUMBER,
                PROCESS_ID: self.header.PROCESS_ID,
                LABEL: self.header.LABEL,
                COOLING: self.header.COOLING,
                OPTION_TEXT: self.header.OPTION_TEXT,
                PAGE_SIZE: self.header.PAGE_SIZE,
                DOC_VERSION: self.header.DOC_VERSION,
            })
                .done(function () { toastOk('기본 정보를 저장했습니다.'); })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.savingHeader = false; });
        },

        // Job Number 와 함께 datasheet 의 PROCESS_ID 를 들고 있어야 사양을 다시 읽을 수 있다.
        pickDatasheet: function (item) {
            this.$set(this.header, 'PROCESS_ID', item ? item.D_ID : null);
            this.specHtml = '';
            this.specMessage = '';
        },

        // 볼 때마다 datasheet 에서 새로 읽는다. 저장하지 않는다.
        openSpec: function () {
            var self = this;
            self.specLoading = true;
            self.specHtml = '';
            self.specMessage = '';
            self.modal('specModal').show();
            $.get('/manual/spec', { mid: self.mid })
                .done(function (res) {
                    self.specHtml = (res.data && res.data.html) || '';
                    self.specMessage = (res.data && res.data.message) || '';
                })
                .fail(function (xhr) { self.specMessage = getErrorMessage(xhr); })
                .always(function () { self.specLoading = false; });
        },

        /* ---------- 멤버 ---------- */
        /* ---------- 문서 스타일 ---------- */
        openDocStyle: function () { this.modal('docStyleModal').show(); },
        saveDocStyle: function () {
            var self = this;
            $.post('/editor/heading-style', {
                mid: self.mid,
                style: JSON.stringify(self.headingStyle),
                bodyFont: self.bodyFont,
                lineHeight: self.bodyLineHeight,
                letterSpacing: self.bodyLetterSpacing,
            })
                .done(function () {
                    self.modal('docStyleModal').hide();
                    self.header.BODY_FONT = self.bodyFont;
                    self.header.BODY_LINE_HEIGHT = self.bodyLineHeight;
                    self.header.BODY_LETTER_SPACING = self.bodyLetterSpacing;
                    toastOk('문서 스타일을 저장했습니다.');
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); });
        },
        headingCss: function (lv) {
            var s = this.headingStyle[lv] || DEFAULT_HEADING_STYLE[lv];
            return {
                fontSize: s.size + 'pt',
                color: s.color,
                fontWeight: s.bold ? 700 : 400,
                textDecoration: s.underline ? 'underline' : 'none',
            };
        },

        goEditor: function () {
            window.location.href = '/editor?mid=' + encodeURIComponent(this.mid);
        },

        /* ---------- 목차 ---------- */
        callTeams: function () {
            var self = this;
            $.get('/manual/teams').done(function (res) { self.teams = res.data.teams; });
        },
        // 서버가 목차별로 내려준 권한을 그대로 따른다.
        canEditSection: function (s) {
            return this.canEdit && s.CAN_EDIT_SEC === 'Y';
        },
        // 목차·템플릿 항목 모두 같은 SEC_TYPE 값을 쓴다.
        isPageBreak: function (s) { return !!s && s.SEC_TYPE === 'PAGEBREAK'; },
        isFirst: function (s) { return this.sections.indexOf(s) === 0; },
        isLast: function (s) { return this.sections.indexOf(s) === this.sections.length - 1; },
        // 목차만 다시 읽는다. 전체 재조회와 달리 화면이 통째로 다시 그려지지 않는다.
        callSections: function () {
            var self = this;
            return $.get('/editor/sections', { mid: self.mid })
                .done(function (res) { self.sections = res.data.list; })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); });
        },
        setSecForm: function (s) {
            this.secForm = s
                ? { SEC_ID: s.SEC_ID, TITLE: s.TITLE, SEC_LEVEL: s.SEC_LEVEL,
                    SEC_NO: s.SEC_NO, ASSIGNED_TEAM: s.ASSIGNED_TEAM, STYLE_JSON: s.STYLE_JSON,
                    TITLE_ALIGN: s.TITLE_ALIGN || 'LEFT', SHOW_IN_TOC: s.SHOW_IN_TOC || 'Y',
                    TITLE_UNDERLINE: s.TITLE_UNDERLINE || 'N' }
                : { SEC_ID: null, TITLE: '', SEC_LEVEL: 1, SEC_NO: '', ASSIGNED_TEAM: null,
                    TITLE_ALIGN: 'LEFT', SHOW_IN_TOC: 'Y', TITLE_UNDERLINE: 'N' };
        },
        openSection: function (s) {
            var self = this;
            self.secError = '';

            if (!s) {
                self.setSecForm(null);
                self.modal('sectionModal').show();
                return;
            }

            // 목록이 오래됐을 수 있으니 편집 대상은 DB 에서 다시 읽어 온다.
            self.secLoading = true;
            $.get('/editor/sections', { mid: self.mid, secId: s.SEC_ID })
                .done(function (res) {
                    self.setSecForm(res.data.section);
                    self.modal('sectionModal').show();
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.secLoading = false; });
        },
        saveSection: function () {
            var self = this;
            if (!self.secForm.TITLE) { self.secError = '제목은 필수입니다.'; return; }

            self.savingSection = true;
            self.secError = '';
            $.post('/editor/section', $.extend({ M_ID: self.mid }, self.secForm))
                .done(function () {
                    self.modal('sectionModal').hide();
                    self.callSections();
                    toastOk('목차를 저장했습니다.');
                })
                .fail(function (xhr) { self.secError = getErrorMessage(xhr); })
                .always(function () { self.savingSection = false; });
        },
        removeSection: function (s) {
            var self = this;
            var message = self.isPageBreak(s)
                ? '페이지 나눔을 삭제합니다.'
                : '"' + s.TITLE + '" 목차를 삭제합니다.\n안에 작성된 내용도 함께 삭제됩니다.';
            if (!confirm(message)) return;

            $.ajax({ url: '/editor/section', method: 'DELETE', data: { secId: s.SEC_ID, mid: self.mid } })
                .done(function () { self.callSections(); toastOk('삭제했습니다.'); })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); });
        },
        moveSection: function (s, delta) {
            var self = this;
            var idx = self.sections.indexOf(s);
            var target = idx + delta;
            if (idx < 0 || target < 0 || target >= self.sections.length) return;

            var arr = self.sections.slice();
            var tmp = arr[idx]; arr[idx] = arr[target]; arr[target] = tmp;
            self.sections = arr;

            var orders = arr.map(function (x, i) { return x.SEC_ID + ':' + (i + 1); }).join(',');
            $.post('/editor/section/order', { mid: self.mid, orders: orders })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); self.callSections(); });
        },
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
                .done(function () {
                    if (!self.isPageBreak(t)) t.IS_ADDED = 'Y';
                    self.callSections();
                    toastOk(self.isPageBreak(t) ? '페이지 나눔을 추가했습니다.' : '"' + t.TITLE + '" 목차를 추가했습니다.');
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.addingTpl = null; });
        },
        // 템플릿에 없어도 바로 넣는다. 맨 뒤에 붙고 ↑↓ 로 자리를 정한다.
        addPageBreak: function () {
            var self = this;
            self.addingPageBreak = true;
            $.post('/editor/section', {
                M_ID: self.mid, TITLE: '페이지 나눔', SEC_LEVEL: 1,
                TITLE_ALIGN: 'LEFT', SEC_TYPE: 'PAGEBREAK',
            })
                .done(function () {
                    self.modal('templateModal').hide();
                    self.callSections();
                    toastOk('페이지 나눔을 추가했습니다.');
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.addingPageBreak = false; });
        },

        /* ---------- 표지 이미지 ---------- */
        pickCover: function () {
            var self = this;
            var input = document.createElement('input');
            input.type = 'file';
            input.accept = 'image/png,image/jpeg,image/gif,image/webp';
            input.addEventListener('change', function () {
                if (input.files && input.files[0]) self.uploadCover(input.files[0]);
            });
            input.click();
        },
        uploadCover: function (file) {
            var self = this;
            var fd = new FormData();
            fd.append('mid', self.mid);
            fd.append('file', file);
            fd.append('__RequestVerificationToken', self.token());

            self.uploadingCover = true;
            $.ajax({ url: '/manual/cover', method: 'POST', data: fd, processData: false, contentType: false })
                .done(function (res) {
                    self.header.COVER_IMAGE_PATH = res.data.path;
                    toastOk('표지 이미지를 등록했습니다.');
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.uploadingCover = false; });
        },
        removeCover: function () {
            var self = this;
            if (!confirm('표지 이미지를 제거합니다.')) return;

            $.ajax({ url: '/manual/cover', method: 'DELETE', data: { mid: self.mid } })
                .done(function () {
                    self.header.COVER_IMAGE_PATH = null;
                    toastOk('제거했습니다.');
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); });
        },
        token: function () {
            return $('#__AjaxAntiForgeryForm input[name="__RequestVerificationToken"]').val();
        },

        /* ---------- 작성 요청 ---------- */
        openNotify: function () {
            var self = this;
            self.notifyError = '';
            self.notifyMemo = '';
            $.get('/manual/notify/recipients', { mid: self.mid })
                .done(function (res) {
                    self.notifyTargetsAll = res.data.list;
                    self.notifyTestMode = res.data.testMode;
                    self.modal('notifyModal').show();
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); });
        },
        sendNotify: function () {
            var self = this;
            self.sendingNotify = true;
            self.notifyError = '';

            $.post('/manual/notify', {
                mid: self.mid,
                memo: self.notifyMemo,
                onlyAssigned: self.notifyOnlyAssigned ? 'Y' : 'N',
            })
                .done(function (res) {
                    self.modal('notifyModal').hide();
                    var msg = res.data.sent.length + '명에게 요청을 보냈습니다.';
                    if (res.data.failed.length) msg += ' 실패 ' + res.data.failed.length + '명.';
                    if (res.data.testMode) msg += ' (TEST 모드: mail-drop 저장)';
                    toastOk(msg);
                })
                .fail(function (xhr) { self.notifyError = getErrorMessage(xhr); })
                .always(function () { self.sendingNotify = false; });
        },
        roleLabel: function (r) {
            return { OWNER: '소유자', EDITOR: '작성자', REVIEWER: '검토자', APPROVER: '승인자' }[r] || r;
        },
        statusLabel: function (s) { return STATUS_LABEL[s] || s; },
        statusClass: function (s) { return STATUS_CLASS[s] || 'badge badge-light'; },
        levelLabel: function (lv) { return { 1: '대제목', 2: '중제목', 3: '소제목' }[lv] || ''; },
        formatDate: formatDateValue,
        formatDateTime: formatDateTimeValue,
    },
});

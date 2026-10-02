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
    CARLITO: "Carlito, 'Malgun Gothic', sans-serif",
    VERDANA: 'Verdana, Geneva, sans-serif',
    TAHOMA: 'Tahoma, Geneva, sans-serif',
    GEORGIA: "Georgia, 'Times New Roman', serif",
    TIMES: "'Times New Roman', Times, serif",
};
// 제목 기본 스타일은 서버(HeadingStyle.Defaults)가 페이지에 넣어 준다.
var DEFAULT_HEADING_STYLE = window.HEADING_DEFAULTS || {};
// 가로 정렬은 STYLE_JSON 과 별개 값이라 따로 다룬다.
var ALIGN_CSS = { LEFT: 'left', CENTER: 'center', RIGHT: 'right' };
function alignCss(a) { return ALIGN_CSS[a] || 'left'; }

// TITLE_UNDERLINE 도 개별 스타일과 별개라 둘 중 하나만 켜도 밑줄을 그린다.
function withUnderline(css, flag) {
    if (flag === 'Y') css.textDecoration = 'underline';
    return css;
}

var BLOCK_LABEL = { TEXT: '텍스트', IMAGE: '이미지', TABLE: '표' };
var CELL_ALIGN = { left: 'left', center: 'center', right: 'right' };
var FN_TOOLBAR = [
    'undo', 'redo', '|', 'fontColor', 'fontBackgroundColor', '|',
    'bold', 'italic', 'underline', 'strikethrough', 'subscript', 'superscript', 'removeFormat', '|',
    'bulletedList', 'numberedList',
];

/* ---------- 표 블록 ----------
   편집용 격자 데이터는 STYLE_JSON 에, 미리보기·PDF 가 그대로 그릴 HTML 은
   CONTENT_HTML 에 넣는다. 두 값은 저장 시점에 함께 만든다.
   rich 가 true 인 열은 셀 값이 HTML 이다(서버가 정제한다). */
function newTable() {
    return {
        head: ['No.', 'Title', 'Function'],
        align: ['center', 'center', 'left'],
        widths: [10, 25, 65],
        rich: [false, false, true],
        rows: [['1', '', ''], ['2', '', '']],
    };
}

// 머리글이 Title / Function 인 열에 등록된 목록을 붙인다.
function tableParamCols(t) {
    var head = t.head.map(function (h) { return $.trim(h).toLowerCase(); });
    var title = head.indexOf('title');
    var func = head.indexOf('function');
    return title >= 0 && func >= 0 ? { title: title, func: func } : null;
}

function tableNoCol(t) {
    return t.head.map(function (h) { return $.trim(h).toLowerCase(); })
        .findIndex(function (h) { return h === 'no' || h === 'no.'; });
}

// 머리글이 No. 인 열은 사용자가 쓰지 않고 행 순서대로 매긴다.
function renumber(t) {
    var col = tableNoCol(t);
    if (col < 0) return;
    t.rows.forEach(function (r, i) { r.splice(col, 1, String(i + 1)); });
}

function textToHtml(v) {
    var s = String(v == null ? '' : v);
    if (!$.trim(s)) return '';
    return '<p>' + escapeHtml(s).replace(/  /g, ' &nbsp;').replace(/\r?\n/g, '<br>') + '</p>';
}

// 비교·목록 표시용 글자만. DOMParser 문서는 스크립트를 실행하지 않는다.
function htmlText(html) {
    var doc = new DOMParser().parseFromString(String(html || ''), 'text/html');
    return (doc.body.textContent || '').replace(/\s+/g, ' ').trim();
}

// 예전 표는 Function 이 평문이다. 편집기로 쓸 수 있게 HTML 로 바꾼다.
function syncRich(t) {
    var cols = tableParamCols(t);
    if (!cols || t.rich[cols.func]) return;
    t.rows.forEach(function (r) { r[cols.func] = textToHtml(r[cols.func]); });
    t.rich[cols.func] = true;
}

function normalizeTable(json) {
    var t = null;
    try { t = json ? JSON.parse(json) : null; }
    catch (e) { t = null; }
    if (!t || !Array.isArray(t.head) || !t.head.length) return newTable();

    var text = function (v) { return v == null ? '' : String(v); };
    var head = t.head.map(text);
    var rows = (Array.isArray(t.rows) ? t.rows : []).map(function (r) {
        var src = Array.isArray(r) ? r : [];
        return head.map(function (_, i) { return text(src[i]); });
    });

    var table = {
        head: head,
        align: head.map(function (_, i) { return CELL_ALIGN[t.align && t.align[i]] || 'left'; }),
        widths: head.map(function (_, i) { return Number(t.widths && t.widths[i]) || 0; }),
        rich: head.map(function (_, i) { return !!(t.rich && t.rich[i] === true); }),
        rows: rows.length ? rows : [head.map(function () { return ''; })],
    };
    syncRich(table);
    renumber(table);
    return table;
}

function escapeHtml(v) {
    return String(v == null ? '' : v)
        .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

function cellHtml(v) {
    return escapeHtml(v).replace(/\r?\n/g, '<br>');
}

// 표 테두리·머리글 배경은 preview.css 가 잡아주므로 여기서는 너비와 정렬만 남긴다.
function tableHtml(t) {
    var cols = t.widths.some(function (w) { return w > 0; })
        ? '<colgroup>' + t.widths.map(function (w) {
            return w > 0 ? '<col style="width:' + w + '%">' : '<col>';
        }).join('') + '</colgroup>'
        : '';

    var head = '<thead><tr>' + t.head.map(function (h, i) {
        return '<th style="text-align:' + (CELL_ALIGN[t.align[i]] || 'center') + '">' + cellHtml(h) + '</th>';
    }).join('') + '</tr></thead>';

    var body = '<tbody>' + t.rows.map(function (r) {
        return '<tr>' + r.map(function (c, i) {
            return '<td style="text-align:' + (CELL_ALIGN[t.align[i]] || 'left') + '">' + (t.rich[i] ? c : cellHtml(c)) + '</td>';
        }).join('') + '</tr>';
    }).join('') + '</tbody>';

    return '<table>' + cols + head + body + '</table>';
}

// 서버에서 받은 블록에 편집용 격자를 붙인다. Vue 가 반응형으로 바꾸기 전에 넣어야 한다.
function prepareBlock(b) {
    if (b && b.ELE_TYPE === 'TABLE') b.TABLE = normalizeTable(b.STYLE_JSON);
    return b;
}

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
        secLoading: false,
        secStyleOn: false,
        secStyle: $.extend({}, DEFAULT_HEADING_STYLE[1]),
        templateOptions: [],
        templateLoading: false,
        addingTpl: null,
        addingPageBreak: false,
        history: [],
        historyLoading: false,
        headingStyle: JSON.parse(JSON.stringify(DEFAULT_HEADING_STYLE)),
        bodyFont: 'CARLITO',
        bodyFontSize: 12,
        bodyLineHeight: 1.2,
        bodyLetterSpacing: 0,
        ckReady: typeof window.createBlockEditor === 'function',
        editorLoading: {},
        dirty: {},
        specHtml: '',
        specMessage: '',
        specLoading: false,
        tableParams: [],
        cellEdit: null,
    },
    computed: {
        canEdit: function () { return this.access && this.access.CAN_EDIT === 'Y'; },
        // 목차에 팀이 지정되면 그 팀만 내용을 고칠 수 있다. 판정은 서버가 한다.
        canEditActive: function () {
            return this.canEdit && !!this.activeSection && this.activeSection.CAN_EDIT_SEC === 'Y';
        },
        secFormCss: function () {
            var base = this.headingStyle[this.secForm.SEC_LEVEL] || DEFAULT_HEADING_STYLE[1];
            return withUnderline($.extend(this.toCss(this.secStyleOn ? this.secStyle : base),
                                          { textAlign: alignCss(this.secForm.TITLE_ALIGN) }),
                                 this.secForm.TITLE_UNDERLINE);
        },
        activeSection: function () {
            var self = this;
            return this.sections.filter(function (s) { return s.SEC_ID === self.activeSecId; })[0] || null;
        },
        // SPECIFICATIONS 목차는 datasheet 에서 바로 읽어 그린다. 판단 기준은 서버와 같다.
        isSpecSection: function () {
            return !!this.activeSection && /SPECIFICATION/i.test(this.activeSection.TITLE || '');
        },
        activeBlocks: function () {
            var self = this;
            return this.blocks
                .filter(function (b) { return b.SEC_ID === self.activeSecId; })
                .sort(function (a, b) { return a.ORDER_NUM - b.ORDER_NUM; });
        },
        dirtyCount: function () {
            var self = this;
            return this.activeBlocks.filter(function (b) { return self.dirty[b.ELE_ID]; }).length;
        },
        hasDirty: function () {
            var self = this;
            return Object.keys(this.dirty).some(function (id) { return self.dirty[id]; });
        },
        // Title(대소문자 무시) → 등록된 Function 목록. 첫 번째가 기본값이다.
        paramMap: function () {
            var map = {};
            this.tableParams.forEach(function (p) {
                var key = $.trim(p.TITLE).toUpperCase();
                (map[key] = map[key] || []).push(p.FUNC_HTML);
            });
            return map;
        },
        paramTitles: function () {
            var seen = {};
            return this.tableParams
                .map(function (p) { return p.TITLE; })
                .filter(function (t) { return seen[t] ? false : (seen[t] = true); });
        },
        // 편집기를 거치면 HTML 표기가 달라지므로 글자로 비교한다.
        paramFuncSet: function () {
            var set = {};
            this.tableParams.forEach(function (p) { set[htmlText(p.FUNC_HTML)] = true; });
            return set;
        },
    },
    watch: {
        activeBlocks: function () { this.$nextTick(this.syncEditors); },
        // 목차를 누를 때마다 datasheet 에서 사양을 다시 가져온다.
        activeSecId: function () { this.loadSpec(); },
        // 개별 지정을 켜기 전까지는 선택한 단계의 공통값을 따라가게 둔다.
        'secForm.SEC_LEVEL': function (lv) {
            if (!this.secStyleOn) this.secStyle = $.extend({}, this.levelStyle(lv));
        },
    },
    created: function () {
        // CKEditor 인스턴스는 객체 그래프가 커서 Vue 반응형으로 만들면 안 된다.
        // data 가 아닌 인스턴스 속성으로 두면 반응형 변환을 피할 수 있다.
        this._editors = {};
        this._cellEditor = null;
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
        self.callTableParams();
        // 미리보기에서 뒤로 가기로 돌아오면 bfcache 복원이라 mounted 가 다시 돌지 않는다.
        window.addEventListener('pageshow', function (e) {
            if (!e.persisted || self.hasDirty) return;
            self.loading = true;
            self.destroyEditors();
            self.callData();
        });
        window.addEventListener('beforeunload', function (e) {
            if (!self.hasDirty) return;
            e.preventDefault();
            e.returnValue = '';
        });
    },
    methods: {
        // 모달 마크업은 v-if 안에 있어 데이터를 다시 불러오면 DOM 이 새로 만들어진다.
        // 인스턴스를 캐시하면 떨어져 나간 예전 요소가 열려 직전 내용이 보인다.
        modal: function (id) {
            var el = document.getElementById(id);
            if (!el) return null;
            return bootstrap.Modal.getOrCreateInstance(el);
        },

        /* ---------- 데이터 ---------- */
        callData: function () {
            var self = this;
            $.get('/editor/data', { mid: self.mid })
                .done(function (res) {
                    self.header = res.data.header;
                    self.sections = res.data.sections;
                    self.blocks = res.data.blocks.map(prepareBlock);
                    self.editorLoading = {};
                    self.dirty = {};
                    self.blocks.forEach(function (block) {
                        if (block.ELE_TYPE === 'TEXT') self.$set(self.editorLoading, block.ELE_ID, true);
                    });
                    self.access = res.data.access;

                    if (self.header && self.header.HEADING_STYLE_JSON) {
                        try { self.headingStyle = $.extend(true, {}, DEFAULT_HEADING_STYLE, JSON.parse(self.header.HEADING_STYLE_JSON)); }
                        catch (e) { /* 저장된 값이 깨졌으면 기본값을 쓴다 */ }
                    }
                    if (self.header) {
                        self.bodyFont = FONT_STACK[self.header.BODY_FONT] ? self.header.BODY_FONT : 'CARLITO';
                        self.bodyFontSize = Number(self.header.BODY_FONT_SIZE) || 12;
                        self.bodyLineHeight = Number(self.header.BODY_LINE_HEIGHT) || 1.2;
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
        callTableParams: function () {
            var self = this;
            $.get('/editor/table-params').done(function (res) { self.tableParams = res.data.list; });
        },

        /* ---------- 목차 ---------- */
        selectSection: function (s) {
            this.destroyEditors();
            this.activeSecId = s.SEC_ID;
        },

        // SPECIFICATIONS 목차의 사양은 저장된 내용이 아니라 누를 때마다 datasheet 에서 읽는다.
        loadSpec: function () {
            var self = this;
            self.specHtml = '';
            self.specMessage = '';
            if (!self.isSpecSection) return;

            self.specLoading = true;
            $.get('/manual/spec', { mid: self.mid })
                .done(function (res) {
                    self.specHtml = (res.data && res.data.html) || '';
                    self.specMessage = (res.data && res.data.message) || '';
                })
                .fail(function (xhr) { self.specMessage = getErrorMessage(xhr); })
                .always(function () { self.specLoading = false; });
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
        setSecForm: function (s) {
            this.secForm = s
                ? { SEC_ID: s.SEC_ID, TITLE: s.TITLE, SEC_LEVEL: s.SEC_LEVEL, SEC_NO: s.SEC_NO,
                    ASSIGNED_TEAM: s.ASSIGNED_TEAM, TITLE_ALIGN: s.TITLE_ALIGN || 'LEFT',
                    SHOW_IN_TOC: s.SHOW_IN_TOC || 'Y', TITLE_UNDERLINE: s.TITLE_UNDERLINE || 'N' }
                : { SEC_ID: null, TITLE: '', SEC_LEVEL: 1, SEC_NO: '', ASSIGNED_TEAM: null,
                    TITLE_ALIGN: 'LEFT', SHOW_IN_TOC: 'Y', TITLE_UNDERLINE: 'N' };

            var own = s ? this.parseStyle(s.STYLE_JSON) : null;
            this.secStyleOn = !!own;
            this.secStyle = $.extend({}, this.levelStyle(this.secForm.SEC_LEVEL), own || {});
        },
        // 목차만 다시 읽는다. 전체 재조회와 달리 본문 편집기가 다시 만들어지지 않는다.
        callSections: function () {
            var self = this;
            return $.get('/editor/sections', { mid: self.mid })
                .done(function (res) { self.sections = res.data.list; })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); });
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
                    self.callSections();
                    if (!self.secForm.SEC_ID) self.activeSecId = newId;
                    toastOk('목차를 저장했습니다.');
                })
                .fail(function (xhr) { self.secError = getErrorMessage(xhr); })
                .always(function () { self.savingSection = false; });
        },
        removeSection: function () {
            var self = this;
            var s = self.activeSection;
            if (!s) return;

            var message = self.isPageBreak(s)
                ? '페이지 나눔을 삭제합니다.'
                : '"' + s.TITLE + '" 목차를 삭제합니다.\n안에 작성된 내용도 함께 삭제됩니다.';
            if (!confirm(message)) return;

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
            if (h.FIELD_NAME === 'TITLE_ALIGN') return '목차 제목 정렬';
            if (h.FIELD_NAME === 'SECTION_ORDER') return '목차 순서';
            if (h.AFTER_VALUE === 'IMAGE') return '이미지 블록';
            if (h.AFTER_VALUE === 'TEXT') return '텍스트 블록';
            if (h.AFTER_VALUE === 'TABLE') return '표 블록';
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
                    if (!self.isPageBreak(t)) t.IS_ADDED = 'Y';
                    self.callData();
                    self.activeSecId = Number(res.data.SEC_ID);
                    toastOk(self.isPageBreak(t) ? '페이지 나눔을 추가했습니다.' : '"' + t.TITLE + '" 목차를 추가했습니다.');
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.addingTpl = null; });
        },
        // 템플릿에 없어도 필요한 자리에 바로 넣는다. 맨 뒤에 붙고 ↑↓ 로 옮긴다.
        addPageBreak: function () {
            var self = this;
            self.addingPageBreak = true;
            $.post('/editor/section', {
                M_ID: self.mid, TITLE: '페이지 나눔', SEC_LEVEL: 1,
                TITLE_ALIGN: 'LEFT', SEC_TYPE: 'PAGEBREAK',
            })
                .done(function (res) {
                    self.modal('templateModal').hide();
                    self.callSections();
                    self.activeSecId = Number(res.data.SEC_ID);
                    toastOk('페이지 나눔을 추가했습니다.');
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.addingPageBreak = false; });
        },

        /* ---------- 본문 블록 ---------- */
        addBlock: function (type) {
            var self = this;
            var order = self.activeBlocks.length + 1;
            var table = type === 'TABLE' ? newTable() : null;

            $.post('/editor/block', {
                M_ID: self.mid, SEC_ID: self.activeSecId, ELE_TYPE: type,
                ORDER_NUM: order, WIDTH: type === 'TEXT' ? 0 : 100, HEIGHT: 0,
                CONTENT_HTML: type === 'TEXT' ? '<p></p>' : (table ? tableHtml(table) : null),
                STYLE_JSON: table ? JSON.stringify(table) : null,
            })
                .done(function (res) { self.blocks.push(prepareBlock(res.data.block)); })
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
                    if (self.cellEdit && self.cellEdit.id === b.ELE_ID) self.closeCellEditor();
                    self.destroyEditor(b.ELE_ID);
                    self.$delete(self.dirty, b.ELE_ID);
                    self.blocks = self.blocks.filter(function (x) { return x.ELE_ID !== b.ELE_ID; });
                    toastOk('삭제했습니다.');
                })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); });
        },
        saveBlock: function (b) {
            var self = this;
            self.saveState = '저장 중...';

            if (b.ELE_TYPE === 'TABLE' && b.TABLE) {
                renumber(b.TABLE);
                b.STYLE_JSON = JSON.stringify(b.TABLE);
                b.CONTENT_HTML = tableHtml(b.TABLE);
            }

            // 동시 편집이 없어 ROW_VER 를 보내지 않는다. 마지막 저장이 그대로 반영된다.
            return $.post('/editor/block', {
                ELE_ID: b.ELE_ID, M_ID: self.mid, SEC_ID: b.SEC_ID, ELE_TYPE: b.ELE_TYPE,
                ORDER_NUM: b.ORDER_NUM, WIDTH: b.WIDTH, HEIGHT: b.HEIGHT,
                CONTENT_HTML: b.CONTENT_HTML, IMAGE_PATH: b.IMAGE_PATH,
                CAPTION: b.CAPTION, STYLE_JSON: b.STYLE_JSON,
            })
                .done(function (res) {
                    if (res.data.block) b.ROW_VER = res.data.block.ROW_VER;
                    self.$set(self.dirty, b.ELE_ID, false);
                    self.saveState = '저장됨';
                    setTimeout(function () { self.saveState = ''; }, 1500);
                })
                .fail(function (xhr) {
                    self.saveState = '저장 실패';
                    toastError(getErrorMessage(xhr));
                });
        },
        markDirty: function (b) {
            this.$set(this.dirty, b.ELE_ID, true);
        },

        /* ---------- 표 블록 ---------- */
        addTableRow: function (b) {
            b.TABLE.rows.push(b.TABLE.head.map(function () { return ''; }));
            renumber(b.TABLE);
            this.markDirty(b);
        },
        removeTableRow: function (b, index) {
            if (b.TABLE.rows.length <= 1) return;
            this.closeCellEditor();
            b.TABLE.rows.splice(index, 1);
            renumber(b.TABLE);
            this.markDirty(b);
        },
        addTableCol: function (b) {
            this.closeCellEditor();
            b.TABLE.head.push('');
            b.TABLE.align.push('left');
            b.TABLE.widths.push(0);
            b.TABLE.rich.push(false);
            b.TABLE.rows.forEach(function (r) { r.push(''); });
            this.markDirty(b);
        },
        removeTableCol: function (b, index) {
            if (b.TABLE.head.length <= 1) return;
            this.closeCellEditor();
            b.TABLE.head.splice(index, 1);
            b.TABLE.align.splice(index, 1);
            b.TABLE.widths.splice(index, 1);
            b.TABLE.rich.splice(index, 1);
            b.TABLE.rows.forEach(function (r) { r.splice(index, 1); });
            this.markDirty(b);
        },
        onHeadInput: function (b) {
            syncRich(b.TABLE);
            renumber(b.TABLE);
            this.markDirty(b);
        },
        noCol: function (b) { return tableNoCol(b.TABLE); },
        setTitle: function (b, ri, ci, title) {
            this.$set(b.TABLE.rows[ri], ci, title);
            this.markDirty(b);
            this.applyParam(b, ri);
        },
        isParamCol: function (b, ci, kind) {
            var cols = tableParamCols(b.TABLE);
            return !!cols && cols[kind] === ci;
        },
        paramOptions: function (b, ri) {
            var cols = tableParamCols(b.TABLE);
            if (!cols) return [];
            return this.paramMap[$.trim(b.TABLE.rows[ri][cols.title]).toUpperCase()] || [];
        },
        paramIndex: function (b, ri, ci) {
            var key = htmlText(b.TABLE.rows[ri][ci]);
            return this.paramOptions(b, ri).map(htmlText).indexOf(key);
        },
        paramLabel: function (html) {
            var s = htmlText(html);
            return s.length > 80 ? s.slice(0, 80) + '…' : s;
        },
        applyParam: function (b, ri) {
            var cols = tableParamCols(b.TABLE);
            var options = this.paramOptions(b, ri);
            if (!cols || !options.length || this.paramIndex(b, ri, cols.func) >= 0) return;

            // 사용자가 직접 고친 내용은 확인 없이 덮지 않는다.
            var current = htmlText(b.TABLE.rows[ri][cols.func]);
            if (current && !this.paramFuncSet[current] &&
                !confirm('작성된 Function 을 등록된 내용으로 바꿉니다.')) return;

            this.setCell(b, ri, cols.func, options[0]);
        },
        pickParam: function (b, ri, ci, index) {
            var f = this.paramOptions(b, ri)[Number(index)];
            if (f != null) this.setCell(b, ri, ci, f);
        },
        setCell: function (b, ri, ci, value) {
            var ed = this._cellEditor;
            if (ed && ed !== 'pending' && this.isCellEditing(b, ri, ci)) ed.setData(value);
            this.$set(b.TABLE.rows[ri], ci, value);
            this.markDirty(b);
        },
        cellRows: function (v) {
            return Math.min(8, Math.max(2, String(v || '').split('\n').length));
        },

        /* 서식 열은 누른 칸에만 편집기를 띄운다. 행마다 만들면 표가 무겁다. */
        isCellEditing: function (b, ri, ci) {
            var e = this.cellEdit;
            return !!e && e.id === b.ELE_ID && e.ri === ri && e.ci === ci;
        },
        openCellEditor: function (b, ri, ci) {
            var self = this;
            if (!self.canEditActive || !self.ckReady || self.isCellEditing(b, ri, ci)) return;

            self.closeCellEditor();
            var target = { id: b.ELE_ID, ri: ri, ci: ci };
            self.cellEdit = target;
            self._cellEditor = 'pending';

            self.$nextTick(function () {
                var host = document.getElementById('cell-' + b.ELE_ID + '-' + ri + '-' + ci);
                if (!host || self.cellEdit !== target) return;

                window.createBlockEditor(host, b.TABLE.rows[ri][ci], {
                    toolbar: FN_TOOLBAR,
                    onChange: function (html) {
                        if (self.cellEdit !== target || html === b.TABLE.rows[ri][ci]) return;
                        self.$set(b.TABLE.rows[ri], ci, html);
                        self.markDirty(b);
                    },
                    onBlur: function () {
                        setTimeout(function () { if (self.cellEdit === target) self.closeCellEditor(); }, 0);
                    },
                }).then(function (editor) {
                    if (self.cellEdit !== target) { editor.destroy(); return; }
                    self._cellEditor = editor;
                    editor.editing.view.focus();
                }).catch(function (err) {
                    if (self.cellEdit === target) self.closeCellEditor();
                    console.error('CKEditor 초기화 실패', err);
                    toastError('편집기를 불러오지 못했습니다.');
                });
            });
        },
        closeCellEditor: function () {
            var ed = this._cellEditor;
            if (ed && ed !== 'pending' && ed.destroy) ed.destroy();
            this._cellEditor = null;
            this.cellEdit = null;
        },
        saveActiveBlocks: function () {
            var self = this;
            var targets = self.activeBlocks.filter(function (b) { return self.dirty[b.ELE_ID]; });
            if (!targets.length) return;

            $.when.apply($, targets.map(function (b) { return self.saveBlock(b); }))
                .done(function () { toastOk('본문을 저장했습니다.'); });
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
                self.$set(self.editorLoading, b.ELE_ID, true);
                window.createBlockEditor(host, b.CONTENT_HTML, {
                    readOnly: !self.canEditActive,
                    uploadUrl: '/editor/image?mid=' + encodeURIComponent(self.mid),
                    uploadHeaders: { RequestVerificationToken: self.token() },
                    onChange: function (html) {
                        if (html === b.CONTENT_HTML) return;
                        b.CONTENT_HTML = html;
                        self.markDirty(b);
                    },
                }).then(function (editor) {
                    self._editors[b.ELE_ID] = editor;
                    self.$set(self.editorLoading, b.ELE_ID, false);
                }).catch(function (err) {
                    delete self._editors[b.ELE_ID];
                    self.$set(self.editorLoading, b.ELE_ID, false);
                    console.error('CKEditor 초기화 실패', err);
                    toastError('편집기를 불러오지 못했습니다.');
                });
            });
        },
        destroyEditor: function (id) {
            var ed = this._editors[id];
            if (ed && ed !== 'pending' && ed.destroy) ed.destroy();
            delete this._editors[id];
            this.$delete(this.editorLoading, id);
        },
        destroyEditors: function () {
            var self = this;
            self.closeCellEditor();
            Object.keys(self._editors).forEach(function (id) { self.destroyEditor(id); });
        },

        /* ---------- 제목 스타일 ---------- */
        /* ---------- 문서 스타일 ---------- */
        // 지정은 문서 정보 화면에서 하고, 여기서는 적용만 한다.
        applyBodyStyle: function () {
            var root = document.documentElement;
            root.style.setProperty('--doc-font', FONT_STACK[this.bodyFont] || FONT_STACK.CARLITO);
            root.style.setProperty('--doc-font-size', this.bodyFontSize + 'pt');
            root.style.setProperty('--doc-line-height', String(this.bodyLineHeight));
            root.style.setProperty('--doc-letter-spacing', this.bodyLetterSpacing + 'px');
        },

        token: function () {
            return $('#__AjaxAntiForgeryForm input[name="__RequestVerificationToken"]').val();
        },
        statusLabel: function (s) { return STATUS_LABEL[s] || s; },
        statusClass: function (s) { return STATUS_CLASS[s] || 'badge badge-light'; },
        blockLabel: function (t) { return BLOCK_LABEL[t] || t; },
        // 목차·템플릿 항목 모두 같은 SEC_TYPE 값을 쓴다.
        isPageBreak: function (s) { return !!s && s.SEC_TYPE === 'PAGEBREAK'; },
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
            return withUnderline($.extend(this.toCss($.extend({}, this.levelStyle(s.SEC_LEVEL), this.parseStyle(s.STYLE_JSON) || {})),
                                          { textAlign: alignCss(s.TITLE_ALIGN) }),
                                 s.TITLE_UNDERLINE);
        },
    },
});

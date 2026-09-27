var STATUS_LABEL = {
    DRAFT: '작성중',
    REVIEW: '결재요청',
    APPROVED: '결재완료',
    PUBLISHED: '발행',
    OBSOLETE: '폐기',
};

var STATUS_CLASS = {
    DRAFT: 'badge badge-light-secondary',
    REVIEW: 'badge badge-light-warning',
    APPROVED: 'badge badge-light-primary',
    PUBLISHED: 'badge badge-light-success',
    OBSOLETE: 'badge badge-light-dark',
};

function formatDateValue(value) {
    if (!value) return '';
    var d = new Date(value);
    if (isNaN(d.getTime())) return '';
    var pad = function (n) { return (n < 10 ? '0' : '') + n; };
    return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate());
}

new Vue({
    el: '#app',
    data: {
        loading: true,
        saving: false,
        list: [],
        filter: { status: '', onlyMine: false },
        form: { MODEL_NAME: '', JOB_NUMBER: '', PROCESS_ID: '', LABEL: '', COOLING: '', OPTION_TEXT: '', PAGE_SIZE: 'LETTER', DOC_VERSION: '1.0' },
        formError: '',
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
            $.get('/manual/list', { status: self.filter.status, onlyMine: self.filter.onlyMine ? 'Y' : 'N' })
                .done(function (res) { self.list = res.data.list; })
                .fail(function (xhr) { toastError(getErrorMessage(xhr)); })
                .always(function () { self.loading = false; });
        },
        openNew: function () {
            this.form = { MODEL_NAME: '', JOB_NUMBER: '', PROCESS_ID: '', LABEL: '', COOLING: '', OPTION_TEXT: '', PAGE_SIZE: 'LETTER', DOC_VERSION: '1.0' };
            this.formError = '';
            this.modal('newManualModal').show();
        },
        // datasheet 의 PROCESS_ID 를 같이 저장해야 나중에 사양을 다시 읽을 수 있다.
        pickDatasheet: function (item) {
            this.form.PROCESS_ID = item ? item.D_ID : '';
        },
        submitNew: function () {
            var self = this;
            if (!self.form.MODEL_NAME) {
                self.formError = 'Model Name 은 필수입니다.';
                return;
            }
            self.saving = true;
            self.formError = '';
            $.post('/manual/create', self.form)
                .done(function (res) {
                    self.modal('newManualModal').hide();
                    window.location.href = '/manual/detail?mid=' + encodeURIComponent(res.data.M_ID);
                })
                .fail(function (xhr) { self.formError = getErrorMessage(xhr); })
                .always(function () { self.saving = false; });
        },
        goDetail: function (mid) {
            window.location.href = '/manual/detail?mid=' + encodeURIComponent(mid);
        },
        statusLabel: function (s) { return STATUS_LABEL[s] || s; },
        statusClass: function (s) { return STATUS_CLASS[s] || 'badge badge-light'; },
        formatDate: formatDateValue,
    },
});

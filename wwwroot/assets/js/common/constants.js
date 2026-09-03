const defaultDatepickerOption = {
    locale: {
        format: 'YYYY-MM-DD',
    },
    position: 'above',
};

const defaultFlatpickerOption = {
    dateFormat: 'Y-m-d',
    onOpen: function (selectedDates, dateStr, instance) {
        instance.setDate(dateStr);
        // 이벤트 충돌로 flatpickr 비활성화
        $('.flatpickr-input:not(:disabled)').attr('disabled', true).addClass('tmpDisabled');
    },
    onClose: function () {
        $('.flatpickr-input.tmpDisabled').removeAttr('disabled').removeClass('tmpDisabled');
    },
};

const authMap = {
    Y: '<div class="badge badge-success">Enabled</div>',
    S: '<div class="badge badge-warning">Waiting for approval</div>',
    N: '<div class="badge badge-danger">Disabled</div>',
};

const roleMap = {
    ADMIN: '<div class="badge badge-primary">Administrator</div>',
    SUPPORTER: '<div class="badge badge-success">Supporter</div>',
    READER: '<div class="badge badge-warning">Reader</div>',
    USER: '<div class="badge badge-info">User</div>',
};

const processStatus = {
    PreRequest: `<span class="badge badge-light">pre-request</span>`,
    Request: `<span class="badge badge-warning">In progress</span>`,
    Completed: '<span class="badge badge-dark">Completed</span>',
    Reject: '<span class="badge badge-danger">Reject</span>',
    SAVE: `<span class="badge badge-light text-danger">Save</span>`,
    Publishing: '<span class="badge badge-warning">Publishing</span>',
    Published: '<span class="badge badge-primary">Published</span>',
    Homepage: '<span class="badge badge-info">Homepage</span>',
    Obsoleted: '<span class="badge badge-dark">Obsolete</span>',
};

const processStatus_text = {
    PreRequest: 'Pre-Request',
    Request: 'Request',
    Completed: 'Completed',
    Reject: 'Reject',
    SAVE: 'Save',
    //Publishing: 'Publishing',
    Published: 'Published',
    Homepage: 'Homepage',
    Obsoleted: 'Obsolete',
};

const typebadge = {
    SYSTEM: '<span class="badge badge-secondary">SYSTEM</span>',
    MODULE: '<span class="badge badge-success">MODULE</span>',
};

const pinCategory = ['D-SUB CONNECTOR PIN ASSIGNMENT','CONNECTOR PIN ASSIGNMENT','PIN ASSIGNMENT','OPTION ORDERING INFORMATION'];

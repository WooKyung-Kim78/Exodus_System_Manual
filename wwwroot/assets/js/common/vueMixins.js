Vue.mixin({
    mounted() {
        $('#app').addClass('opacity-100');
    },
    methods: {
        getApprovalStatus(status) {
            const map = {
                Request: '<span class="badge badge-sm badge-light">Request</span>',
                APPROVAL: '<span class="badge badge-sm badge-light">Approval</span>',
                ForwardApproval: '<span class="badge badge-sm badge-light">Approval</span>',
                REJECT: '<span class="badge badge-sm badge-danger">Reject</span>',
            };
            return map[status];
        },
        getType(type) {
            const typebadge = {
                SYSTEM: '<span class="badge badge-secondary">SYSTEM</span>',
                MODULE: '<span class="badge badge-success">MODULE</span>',
            };
            return typebadge[type];
        },
        numberFormat(number) {
            return numberFormat(number);
        },
        numberStrToNum(string) {
            return numberStrToNum(string);
        },
        closeDrawer(id) {
            const drawer = KTDrawer.getInstance(document.getElementById(id));
            drawer.hide();
        },
        openDrawer(id, callbackObj) {
            const drawer = KTDrawer.getInstance(document.getElementById(id));
            $('body').addClass('overflow-hidden');
            drawer.on('kt.drawer.hide', () => {
                $('body').removeClass('overflow-hidden');
                if (callbackObj?.onHide) callbackObj.onHide();
            });
            drawer.show();
        },
    },
});

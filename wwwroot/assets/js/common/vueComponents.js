Vue.component('flat-picker', {
    props: {
        value: String,
        name: String,
        className: {
            type: String,
            default() {
                return '';
            },
        },
        disabled: [String, Boolean, Number],
        defaulttoday: Boolean,
        id: {
            type: String,
            default() {
                return guid();
            },
        },
    },
    template: `
        <div>
            <input :name="name" :class="'form-control ' + className" :disabled="!!disabled" :id="id" v-model="displayValue" :defaultToday="defaulttoday" />
        </div>`,
    data: function () {
        return {
            flatpickr: null,
            init: false,
        };
    },
    mounted() {
        this.$nextTick(() => {
            this.flatpickr = $('#' + this.id).flatpickr(defaultFlatpickerOption);
            if ($('#' + this.id).attr('defaulttoday')) {
                $('#' + this.id).val(getToday());
            }
        });
    },
    computed: {
        displayValue: {
            get: function () {
                if (this.flatpickr && this.value && !this.init) {
                    this.flatpickr.setDate(this.value);
                    this.init = true;
                }
                return this.value;
            },
            set: function (value) {
                this.$emit('input', value);
                return;
            },
        },
    },
});
Vue.component('date-range', {
    props: {
        disabled: Boolean,
        value: String,
        name: String,
        className: {
            type: String,
            default() {
                return '';
            },
        },
        id: {
            type: String,
            default() {
                return guid();
            },
        },
    },
    template: `
        <div>
            <input :name="name" :class="'form-control form-control-solid ' + className" readonly :id="id" v-model="displayValue" :disabled="disabled" />
        </div>`,
    data: function () {
        return {
            ragePicker: null,
        };
    },
    updated() {
        $('#' + this.id).prop('disabled', this.disabled);
    },
    mounted() {
        this.$nextTick(() => {
            this.ragePicker = $('#' + this.id).daterangepicker({
                ...defaultDatepickerOption,
                autoUpdateInput: false,
                showDropdowns: true,
                drops: 'up',
            });
            $('#' + this.id).on('apply.daterangepicker', (ev, picker) => {
                const value = picker.startDate.format('YYYY-MM-DD') + ' - ' + picker.endDate.format('YYYY-MM-DD');
                $('#' + this.id).val(value);
                this.$emit('input', value);
            });
            $('#' + this.id).on('cancel.daterangepicker', (ev, picker) => {
                const value = '';
                $('#' + this.id).val(value);
                picker.setStartDate({});
                picker.setEndDate({});
                this.$emit('input', value);
            });
        });
    },
    computed: {
        displayValue: {
            get: function () {
                if (this.ragePicker && this.value) $('#' + this.id).val(this.value);
                return this.value;
            },
            set: function (value) {
                this.$emit('input', value);
                return;
            },
        },
    },
});

Vue.component('select2', {
    props: {
        value: [String, Array],
        name: String,
        className: {
            type: String,
            default() {
                return '';
            },
        },
        disabled: String,
        id: {
            type: String,
            default() {
                return guid();
            },
        },
        tag: String,
        parent: String,
        multiple: String,
    },
    template: `
        <select :class="'form-select ' + className" :disabled="disabled" :id="id" data-placeholder="Select data" data-allow-clear="true" :tag="false" :multiple="multiple">
            <slot />
        </select>`,
    data: function () {
        return {
            select2: null,
        };
    },
    mounted() {
        this.$nextTick(() => {
            this.init();
        });
    },
    updated() {
        this.$nextTick(() => {
            this.init();
        });
    },
    methods: {
        init() {
            const $el = $('#' + this.id);
            $el.val(this.value);

            this.$nextTick(() => {
                let parent = $('#' + this.parent);
                if ($el.closest('.modal')) {
                    parent = $el.closest('.modal');
                }
                this.select2 = $el.select2({
                    ...(parent.length ? { dropdownParent: parent } : {}),
                    tags: this.tag,
                });

                if ($el.attr('multiple')) {
                    $el.find('option.plz_select').remove();
                }
                if ($el.attr('tag')) {
                    $el.find('option.plz_select').remove();
                }
                $el.off('change');
                $el.on('change', event => {
                    this.$emit('input', $el.val());
                });
            });
        },
    },
});

Vue.component('currency-input', {
    props: ['value', 'name', 'className', 'maxlength', 'disabled', 'minus', 'max', 'focusFl', 'fixed', 'fill'],
    template: `
        <div>
            <input :name="name" :class="className" :disabled="disabled" :maxlength="maxlength" :max="max" type="text" v-model="displayValue" @blur="isInputActive = false" @focus="isInputActive=true" @input="filterNumber($event)" onfocus="this.select()" />
        </div>`,
    data: function () {
        return {
            isInputActive: false,
        };
    },
    computed: {
        displayValue: {
            get: function () {
                if (this.isInputActive && this.value) {
                    return this.value.toString();
                } else {
                    let value = numberFormat(this.value, this.fixed, this.fill === true);
                    this.$emit('input', numberStrToNum(value));
                    return value;
                }
            },
            set: function (modifiedValue) {
                let regEx = /[^\d\.]/g;
                if (this.minus) regEx = /[^-0-9]/g;
                let newValue = parseFloat(modifiedValue.replace(regEx, ''));
                if (this.fixed) {
                    newValue = modifiedValue.replace(regEx, '');
                }

                if (isNaN(newValue)) {
                    newValue = 0;
                }
                if (typeof this.max === 'number' || typeof this.max === 'string') {
                    const max = +this.max;
                    if (newValue > max) newValue = max;
                }
                this.$emit('input', newValue);
            },
        },
    },
    methods: {
        filterNumber(event) {
            let regEx = /[^\d\.]/g;
            if (this.minus) regEx = /[^-0-9]/g;
            let value = event.target.value.replace(regEx, '');
            if (typeof this.max === 'number' || typeof this.max === 'string') {
                const max = +this.max;
                if (value > max) value = max;
            }
            event.target.value = value;
        },
    },
});

Vue.filter('currency', function (value) {
    if (value || value == 0) {
        return String(value).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    }
});
Vue.filter('formatDate', function (value) {
    if (value) {
        return moment(String(value)).format('YYYY-MM-DD');
    }
});

Vue.filter('formatDateTime', function (value) {
    if (value) {
        return moment(String(value)).format('YYYY-MM-DD HH:mm:ss');
    }
});

Vue.filter('formatDateToday', function (value) {
    if (value) {
        return moment(String(new Date())).format('YYYY-MM-DD');
    }
});

Vue.filter('nullCheck', function (value) {
    if (value != '' && value != null && value != undefined) {
        return value;
    } else {
        return '';
    }
});

Vue.filter('innerText', function (value) {
    if (value) {
        return getInnerTextFromHTML(value);
    }
});

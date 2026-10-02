/* Model Name 선택용 검색 가능한 셀렉트.
   exodus_datasheet 에서 발행된 datasheet 의 NAME 목록을 불러와 고르게 한다.
   allowFree 면 목록에 없는 값도 직접 입력할 수 있다(이때는 datasheet 연결이 풀린다). */
(function () {
    var cache = null;
    var pending = null;

    function loadOptions() {
        if (cache) return $.Deferred().resolve(cache).promise();
        if (!pending) {
            pending = $.get('/manual/datasheets').then(function (res) {
                cache = (res.data && res.data.list) || [];
                pending = null;
                return cache;
            }, function (xhr) {
                pending = null;
                return $.Deferred().reject(getErrorMessage(xhr)).promise();
            });
        }
        return pending;
    }

    Vue.component('datasheet-select', {
        props: {
            value: { type: String, default: '' },
            disabled: { type: Boolean, default: false },
            allowFree: { type: Boolean, default: false },
            placeholder: { type: String, default: 'Model Name 검색 (datasheet)' },
        },
        data: function () {
            return { list: [], keyword: '', open: false, loading: false, error: '' };
        },
        computed: {
            filtered: function () {
                var k = this.keyword.trim().toLowerCase();
                var list = k
                    ? this.list.filter(function (d) {
                        return (d.NAME || '').toLowerCase().indexOf(k) > -1
                            || (d.TITLE || '').toLowerCase().indexOf(k) > -1;
                    })
                    : this.list;
                return list.slice(0, 50);
            },
        },
        methods: {
            onFocus: function () {
                if (this.disabled) return;
                this.keyword = this.allowFree ? (this.value || '') : '';
                this.open = true;
                this.load();
            },
            onInput: function (e) {
                this.keyword = e.target.value;
                this.open = true;
                if (this.allowFree) {
                    this.$emit('input', this.keyword.trim());
                    this.$emit('select', null);
                }
            },
            // 목록 항목 클릭은 mousedown 에서 처리하므로 blur 를 조금 늦춘다.
            onBlur: function () {
                var self = this;
                setTimeout(function () { self.open = false; self.keyword = ''; }, 150);
            },
            load: function () {
                var self = this;
                if (self.list.length || self.loading) return;
                self.loading = true;
                self.error = '';
                loadOptions()
                    .done(function (list) { self.list = list; })
                    .fail(function (message) { self.error = message || 'datasheet 목록을 불러오지 못했습니다.'; })
                    .always(function () { self.loading = false; });
            },
            select: function (item) {
                this.$emit('input', item.NAME);
                this.$emit('select', item);
                this.open = false;
                this.keyword = '';
            },
            clear: function () {
                if (this.disabled) return;
                this.$emit('input', '');
                this.$emit('select', null);
                this.open = false;
                this.keyword = '';
            },
        },
        template:
            '<div class="position-relative">' +
            '  <div class="input-group">' +
            '    <input type="text" class="form-control" autocomplete="off" :placeholder="placeholder"' +
            '           :disabled="disabled" :value="open ? keyword : (value || \'\')"' +
            '           @focus="onFocus" @input="onInput" @blur="onBlur" @keydown.esc="open = false" />' +
            '    <button v-if="!disabled" type="button" class="btn btn-light" title="지우기"' +
            '            @mousedown.prevent="clear">&times;</button>' +
            '  </div>' +
            '  <div v-if="open" class="card shadow-sm position-absolute w-100"' +
            '       style="z-index:1060;top:100%;left:0;max-height:260px;overflow-y:auto">' +
            '    <div v-if="loading" class="px-4 py-3 text-muted fs-8">불러오는 중...</div>' +
            '    <div v-else-if="error" class="px-4 py-3 text-danger fs-8">{{ error }}</div>' +
            '    <div v-else-if="!filtered.length" class="px-4 py-3 text-muted fs-8">검색 결과가 없습니다.</div>' +
            '    <a v-for="d in filtered" :key="d.D_ID" href="javascript:;"' +
            '       class="d-block px-4 py-2 text-gray-800 text-hover-primary border-bottom"' +
            '       @mousedown.prevent="select(d)">' +
            '      <span class="fw-bold">{{ d.NAME }}</span>' +
            '      <span v-if="d.DS_VERSION" class="badge badge-light fs-9 ms-2">Rev {{ d.DS_VERSION }}</span>' +
            '      <span v-if="d.TITLE" class="d-block text-muted fs-8 text-truncate">{{ d.TITLE }}</span>' +
            '    </a>' +
            '  </div>' +
            '</div>',
    });
})();

/* 표 Title 칸용 검색 가능한 셀렉트. 목록에 없으면 입력한 글자를 그대로 쓸 수 있다.
   표가 .table-responsive(overflow) 안에 있어 목록은 position:fixed 로 띄운다. */
Vue.component('title-select', {
    props: {
        value: { type: String, default: '' },
        options: { type: Array, default: function () { return []; } },
        disabled: { type: Boolean, default: false },
        align: { type: String, default: 'left' },
        placeholder: { type: String, default: 'Title 검색' },
    },
    data: function () {
        return { keyword: '', open: false, active: 0, pos: {} };
    },
    computed: {
        filtered: function () {
            var k = this.keyword.trim().toLowerCase();
            return k
                ? this.options.filter(function (t) { return t.toLowerCase().indexOf(k) > -1; })
                : this.options;
        },
        // 입력한 글자가 목록과 정확히 같지 않으면 맨 위에 '직접 입력' 을 둔다.
        custom: function () {
            var k = this.keyword.trim();
            if (!k) return '';
            var lower = k.toLowerCase();
            return this.options.some(function (t) { return t.toLowerCase() === lower; }) ? '' : k;
        },
        items: function () {
            return (this.custom ? [this.custom] : []).concat(this.filtered);
        },
    },
    watch: {
        keyword: function () { this.active = 0; },
    },
    beforeDestroy: function () {
        this.unbind();
    },
    methods: {
        onFocus: function () {
            if (this.disabled) return;
            this.keyword = '';
            this.active = Math.max(0, this.options.indexOf(this.value));
            this.place();
            this.open = true;
            this.bind();
            this.$nextTick(this.scrollActive);
        },
        onBlur: function () {
            var self = this;
            setTimeout(function () { self.close(); }, 150);
        },
        onInput: function (e) {
            this.keyword = e.target.value;
            this.open = true;
        },
        move: function (delta) {
            if (!this.open || !this.items.length) return;
            this.active = (this.active + delta + this.items.length) % this.items.length;
            this.$nextTick(this.scrollActive);
        },
        enter: function () {
            if (!this.open) return;
            var item = this.items[this.active];
            if (item != null) this.select(item);
        },
        select: function (title) {
            this.close();
            this.$refs.input.blur();
            if (title !== this.value) this.$emit('input', title);
        },
        close: function () {
            this.open = false;
            this.keyword = '';
            this.unbind();
        },
        place: function () {
            var r = this.$refs.input.getBoundingClientRect();
            this.pos = { top: r.bottom + 2 + 'px', left: r.left + 'px', minWidth: r.width + 'px' };
        },
        scrollActive: function () {
            var list = this.$refs.list;
            var el = list && list.children[this.active];
            if (el) el.scrollIntoView({ block: 'nearest' });
        },
        bind: function () {
            if (this._onMove) return;
            this._onMove = this.place.bind(this);
            window.addEventListener('scroll', this._onMove, true);
            window.addEventListener('resize', this._onMove);
        },
        unbind: function () {
            if (!this._onMove) return;
            window.removeEventListener('scroll', this._onMove, true);
            window.removeEventListener('resize', this._onMove);
            this._onMove = null;
        },
    },
    template:
        '<div class="title-select">' +
        '  <input ref="input" type="text" class="form-control form-control-sm" autocomplete="off"' +
        '         :placeholder="open ? (value || placeholder) : placeholder" :disabled="disabled"' +
        '         :style="{ textAlign: align }" :value="open ? keyword : value" maxlength="200"' +
        '         @focus="onFocus" @blur="onBlur" @input="onInput"' +
        '         @keydown.down.prevent="move(1)" @keydown.up.prevent="move(-1)"' +
        '         @keydown.enter.prevent="enter" @keydown.esc="$refs.input.blur()" />' +
        '  <div v-if="open" ref="list" class="title-select-menu card shadow-sm" :style="pos">' +
        '    <div v-if="!items.length" class="px-3 py-2 text-muted fs-8">등록된 Title 이 없습니다.</div>' +
        '    <a v-for="(t, i) in items" :key="i" href="javascript:;"' +
        '       class="d-block px-3 py-2 fs-8 text-gray-800"' +
        '       :class="{ active: i === active, \'fw-bold\': t === value }"' +
        '       @mouseenter="active = i" @mousedown.prevent="select(t)">' +
        '      <template v-if="custom && i === 0"><span class="text-muted">직접 입력:</span> {{ t }}</template>' +
        '      <template v-else>{{ t }}</template>' +
        '    </a>' +
        '  </div>' +
        '</div>',
});

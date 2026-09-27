// 좁은 화면에서 좌측 네비게이션을 열고 닫는다.
(function () {
    var burger = document.getElementById('exBurger');
    if (!burger) return;

    var backdrop = null;

    function close() {
        document.body.classList.remove('ex-nav-open');
        if (backdrop) { backdrop.remove(); backdrop = null; }
    }

    burger.addEventListener('click', function () {
        if (document.body.classList.contains('ex-nav-open')) { close(); return; }
        document.body.classList.add('ex-nav-open');
        backdrop = document.createElement('div');
        backdrop.className = 'ex-backdrop';
        backdrop.addEventListener('click', close);
        document.body.appendChild(backdrop);
    });

    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') close();
    });
})();

// 넓은 화면에서 좌측 네비게이션을 아이콘만 남기고 접는다.
(function () {
    var btn = document.getElementById('exCollapse');
    if (!btn) return;

    var KEY = 'exSidebarCollapsed';
    var root = document.documentElement;
    var items = document.querySelectorAll('.ex-nav-item');

    function apply(collapsed) {
        root.classList.toggle('ex-collapsed', collapsed);
        btn.setAttribute('aria-expanded', collapsed ? 'false' : 'true');
        btn.title = collapsed ? '메뉴 펼치기' : '메뉴 접기';
        btn.setAttribute('aria-label', btn.title);

        // 글자가 사라지므로 접었을 때만 아이콘에 이름을 툴팁으로 붙인다.
        Array.prototype.forEach.call(items, function (a) {
            var label = a.querySelector('span');
            if (!label) return;
            if (collapsed) a.title = label.textContent.trim();
            else a.removeAttribute('title');
        });
    }

    apply(root.classList.contains('ex-collapsed'));

    btn.addEventListener('click', function () {
        var collapsed = !root.classList.contains('ex-collapsed');
        apply(collapsed);
        try { localStorage.setItem(KEY, collapsed ? '1' : '0'); } catch (e) { /* 저장 불가면 이번 세션만 적용 */ }
    });
})();

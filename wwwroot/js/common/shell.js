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

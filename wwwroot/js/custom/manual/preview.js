// PDF 는 서버(ManualController.Pdf)가 Chromium 으로 만든다. 글자가 벡터로 들어가 확대해도 깨지지 않는다.
$(function () {
    var $btn = $('#btnPdf');
    var $state = $('#pdfState');
    var $btnFlow = $('#btnFlow');
    var $btnPages = $('#btnPages');
    var $stage = $('.preview-stage');
    var frame = document.getElementById('pdfFrame');
    var sheet = document.getElementById('docSheet');
    var mid = $btn.data('mid');
    var pdfPromise = null;

    // 화면 내용은 이 페이지를 연 시점 기준이므로 PDF 도 한 번만 만들어 다운로드와 페이지 보기가 같이 쓴다.
    function loadPdf() {
        if (pdfPromise) return pdfPromise;

        $btn.prop('disabled', true);
        $btnPages.prop('disabled', true);
        $state.text('PDF 만드는 중...');

        pdfPromise = fetch('/manual/pdf?mid=' + encodeURIComponent(mid), { credentials: 'same-origin' })
            .then(function (res) {
                if (res.ok) return res.blob();
                return res.json()
                    .catch(function () { return {}; })
                    .then(function (body) { throw new Error(body.message || 'PDF 생성에 실패했습니다.'); });
            })
            .then(function (blob) {
                $state.text('');
                return blob;
            })
            .catch(function (err) {
                pdfPromise = null;
                console.error(err);
                $state.text('실패');
                toastError(err.message || 'PDF 생성에 실패했습니다.');
                throw err;
            })
            .finally(function () {
                $btn.prop('disabled', false);
                $btnPages.prop('disabled', false);
            });
        return pdfPromise;
    }

    function setMode(pages) {
        $btnFlow.toggleClass('btn-secondary', !pages).toggleClass('btn-light', pages);
        $btnPages.toggleClass('btn-secondary', pages).toggleClass('btn-light', !pages);
        $stage.toggleClass('d-none', pages);
        $(frame).toggleClass('d-none', !pages);
    }

    $btnFlow.on('click', function () { setMode(false); });

    $btnPages.on('click', function () {
        if (!mid) return;
        if (frame.src) { setMode(true); return; }

        loadPdf().then(function (blob) {
            frame.src = URL.createObjectURL(blob);
            setMode(true);
        }, function () { });
    });

    $btn.on('click', function () {
        if (!sheet || !mid) return;

        loadPdf().then(function (blob) {
            var url = URL.createObjectURL(blob);
            var link = document.createElement('a');
            link.href = url;
            link.download = sheet.dataset.filename || 'manual.pdf';
            document.body.appendChild(link);
            link.click();
            link.remove();
            setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
            $state.text('완료');
            setTimeout(function () { $state.text(''); }, 2000);
        }, function () { });
    });
});

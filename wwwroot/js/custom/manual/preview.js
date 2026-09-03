$(function () {
    var $btn = $('#btnPdf');
    var $state = $('#pdfState');

    $btn.on('click', function () {
        var sheet = document.getElementById('docSheet');
        if (!sheet) return;

        // html2canvas 는 이미지 로드가 끝나야 제대로 그린다.
        var pending = Array.prototype.filter.call(sheet.querySelectorAll('img'), function (img) {
            return !img.complete;
        });

        $btn.prop('disabled', true);
        $state.text('PDF 만드는 중...');

        Promise.all(pending.map(function (img) {
            return new Promise(function (resolve) {
                img.addEventListener('load', resolve, { once: true });
                img.addEventListener('error', resolve, { once: true });
            });
        })).then(function () {
            var isA4 = sheet.classList.contains('a4');

            return html2pdf()
                .set({
                    filename: sheet.dataset.filename || 'manual.pdf',
                    margin: 0,
                    pagebreak: { mode: ['css', 'legacy'], before: '.page-break', avoid: '.avoid-break' },
                    html2canvas: { scale: 2, useCORS: true, logging: false, scrollY: 0 },
                    jsPDF: { unit: 'mm', format: isA4 ? 'a4' : 'letter', orientation: 'portrait' },
                })
                .from(sheet)
                .toPdf()
                .get('pdf')
                .then(function (pdf) {
                    var total = pdf.internal.getNumberOfPages();
                    var w = pdf.internal.pageSize.getWidth();
                    var hgt = pdf.internal.pageSize.getHeight();

                    // 표지(1페이지)를 제외하고 페이지 번호를 넣는다.
                    for (var i = 2; i <= total; i++) {
                        pdf.setPage(i);
                        pdf.setFontSize(8);
                        pdf.setTextColor(120, 130, 157);
                        pdf.text(String(i - 1), w / 2, hgt - 8, { align: 'center' });
                    }
                })
                .save();
        }).then(function () {
            $state.text('완료');
            setTimeout(function () { $state.text(''); }, 2000);
        }).catch(function (err) {
            console.error(err);
            $state.text('실패');
            toastError('PDF 생성에 실패했습니다.');
        }).then(function () {
            $btn.prop('disabled', false);
        });
    });
});

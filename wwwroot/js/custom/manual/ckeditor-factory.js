import {
    ClassicEditor,
    Alignment,
    Autoformat,
    BlockQuote,
    Bold,
    Essentials,
    FontBackgroundColor,
    FontColor,
    Heading,
    ImageBlock,
    ImageInsert,
    ImageResize,
    ImageStyle,
    ImageToolbar,
    ImageUpload,
    Indent,
    IndentBlock,
    Italic,
    Link,
    List,
    Paragraph,
    PasteFromOffice,
    RemoveFormat,
    Strikethrough,
    Subscript,
    Superscript,
    SimpleUploadAdapter,
    Table,
    TableCaption,
    TableCellProperties,
    TableColumnResize,
    TableProperties,
    TableToolbar,
    TextTransformation,
    Underline,
} from 'ckeditor5';

const TOOLBAR = [
    'undo', 'redo', '|',
    'heading', '|',
    'fontColor', 'fontBackgroundColor', '|',
    'bold', 'italic', 'underline', 'strikethrough', 'subscript', 'superscript', 'removeFormat', '|',
    'alignment', 'bulletedList', 'numberedList', 'outdent', 'indent', '|',
    'insertTable', 'tableProperties', 'tableCellProperties', '|',
    'uploadImage', 'link', 'blockQuote',
];

const PLUGINS = [
    Alignment, Autoformat, BlockQuote, Bold, Essentials,
    FontBackgroundColor, FontColor, Heading,
    ImageBlock, ImageInsert, ImageResize, ImageStyle, ImageToolbar, ImageUpload,
    Indent, IndentBlock, Italic, Link, List, Paragraph, PasteFromOffice, RemoveFormat,
    Strikethrough, Subscript, Superscript,
    SimpleUploadAdapter,
    Table, TableCaption, TableCellProperties, TableColumnResize, TableProperties, TableToolbar,
    TextTransformation, Underline,
];

const WORD_HTML = /ProgId\s+content="?Word\.Document|urn:schemas-microsoft-com:office:word/i;

// 표·그림·목록의 구조와 이미지 업로드에 필요한 속성만 남긴다. 나머지(글꼴·색·정렬·표 테두리 등)는 지운다.
const KEEP_ATTRIBUTES = new Set([
    'listItemId', 'listType', 'listIndent',
    'colspan', 'rowspan', 'headingRows', 'headingColumns',
    'src', 'srcset', 'alt', 'uploadId', 'uploadStatus',
]);

// Word 에서 붙여넣은 내용은 표·그림은 두고 서식만 모두 지운다. 그림은 PasteFromOffice 가 꺼낸 뒤 업로드된다.
function stripWordFormatting(editor) {
    let fromWord = false;

    editor.editing.view.document.on('clipboardInput', (evt, data) => {
        fromWord = WORD_HTML.test(data.dataTransfer.getData('text/html') || '');
    }, { priority: 'highest' });

    editor.plugins.get('ClipboardPipeline').on('contentInsertion', (evt, data) => {
        if (!fromWord) return;
        fromWord = false;

        editor.model.change(writer => {
            const content = data.content;
            const elements = [];
            const keys = new Set();

            for (const item of writer.createRangeIn(content).getItems()) {
                if (item.is('element')) elements.push(item);
                for (const key of item.getAttributeKeys()) {
                    if (!KEEP_ATTRIBUTES.has(key)) keys.add(key);
                }
            }

            // 범위로 지우면 바로 아래 자식에만 적용되므로 모든 컨테이너를 돌며 지운다.
            for (const container of [content, ...elements]) {
                const range = writer.createRangeIn(container);
                for (const key of keys) writer.removeAttribute(key, range);
            }

            for (const element of elements) {
                if (/^heading\d$/.test(element.name)) writer.rename(element, 'paragraph');
            }
        });
    }, { priority: 'high' });
}

/**
 * Vue(클래식 스크립트)에서 호출할 수 있도록 전역에 팩토리를 노출한다.
 * ckeditor5 빌드가 ESM 이라 import map + module 스크립트로만 로드할 수 있다.
 */
window.createBlockEditor = async function (element, initialHtml, options) {
    const opts = options || {};

    const editor = await ClassicEditor.create(element, {
        licenseKey: 'GPL',
        plugins: PLUGINS,
        toolbar: opts.toolbar
            ? { items: opts.toolbar, shouldNotGroupWhenFull: false }
            : { items: TOOLBAR, shouldNotGroupWhenFull: true },
        table: {
            contentToolbar: ['tableColumn', 'tableRow', 'mergeTableCells', 'tableProperties', 'tableCellProperties'],
        },
        // 문단 정렬(alignment)은 이미지에 걸리지 않아 이미지를 선택하면 나오는 도구모음으로 정렬한다.
        image: {
            styles: { options: ['alignBlockLeft', 'block', 'alignBlockRight'] },
            // 모서리를 끌어도 되고 드롭다운으로 고를 수도 있다. % 단위라 용지 크기가 달라도 비율이 유지된다.
            resizeUnit: '%',
            resizeOptions: [
                { name: 'resizeImage:original', value: null, label: '원본' },
                { name: 'resizeImage:25', value: '25', label: '25%' },
                { name: 'resizeImage:50', value: '50', label: '50%' },
                { name: 'resizeImage:75', value: '75', label: '75%' },
                { name: 'resizeImage:100', value: '100', label: '100%' },
            ],
            toolbar: [
                'imageStyle:alignBlockLeft', 'imageStyle:block', 'imageStyle:alignBlockRight', '|',
                'resizeImage',
            ],
        },
        link: { addTargetToExternalLinks: true },
        simpleUpload: opts.uploadUrl ? {
            uploadUrl: opts.uploadUrl,
            headers: opts.uploadHeaders || {},
        } : undefined,
    });

    editor.setData(initialHtml || '');
    stripWordFormatting(editor);

    if (opts.readOnly) editor.enableReadOnlyMode('app');
    if (typeof opts.onChange === 'function') {
        editor.model.document.on('change:data', () => opts.onChange(editor.getData()));
    }
    if (typeof opts.onBlur === 'function') {
        editor.ui.focusTracker.on('change:isFocused', (_evt, _name, isFocused) => {
            if (!isFocused) opts.onBlur(editor.getData());
        });
    }

    return editor;
};

window.dispatchEvent(new Event('ckeditor-ready'));

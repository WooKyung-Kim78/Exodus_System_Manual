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
    ImageToolbar,
    ImageUpload,
    Indent,
    IndentBlock,
    Italic,
    Link,
    List,
    Paragraph,
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
    ImageBlock, ImageInsert, ImageToolbar, ImageUpload,
    Indent, IndentBlock, Italic, Link, List, Paragraph, RemoveFormat,
    Strikethrough, Subscript, Superscript,
    SimpleUploadAdapter,
    Table, TableCaption, TableCellProperties, TableColumnResize, TableProperties, TableToolbar,
    TextTransformation, Underline,
];

/**
 * Vue(클래식 스크립트)에서 호출할 수 있도록 전역에 팩토리를 노출한다.
 * ckeditor5 빌드가 ESM 이라 import map + module 스크립트로만 로드할 수 있다.
 */
window.createBlockEditor = async function (element, initialHtml, options) {
    const opts = options || {};

    const editor = await ClassicEditor.create(element, {
        licenseKey: 'GPL',
        plugins: PLUGINS,
        toolbar: { items: TOOLBAR, shouldNotGroupWhenFull: true },
        table: {
            contentToolbar: ['tableColumn', 'tableRow', 'mergeTableCells', 'tableProperties', 'tableCellProperties'],
        },
        link: { addTargetToExternalLinks: true },
        simpleUpload: opts.uploadUrl ? {
            uploadUrl: opts.uploadUrl,
            headers: opts.uploadHeaders || {},
        } : undefined,
    });

    editor.setData(initialHtml || '');

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

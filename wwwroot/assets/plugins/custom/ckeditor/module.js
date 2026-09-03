import {
    InlineEditor,
    AccessibilityHelp,
    Alignment,
    Autoformat,
    Autosave,
    Bold,
    Essentials,
    FontBackgroundColor,
    FontColor,
    Indent,
    IndentBlock,
    Italic,
    Paragraph,
    SelectAll,
    SpecialCharacters,
    Strikethrough,
    Subscript,
    Superscript,
    Table,
    TableCaption,
    TableCellProperties,
    TableColumnResize,
    TableProperties,
    TableToolbar,
    TextTransformation,
    Underline,
} from 'ckeditor5';

const option = {
    toolbar: {
        items: ['insertTable', '|', 'fontColor', 'fontBackgroundColor', '|', 'bold', 'italic', 'underline', 'strikethrough', 'subscript', 'superscript', '|', 'alignment', '|', 'outdent', 'indent'],
        shouldNotGroupWhenFull: false,
    },
    plugins: [
        AccessibilityHelp,
        Alignment,
        Autoformat,
        Autosave,
        Bold,
        Essentials,
        FontBackgroundColor,
        FontColor,
        Indent,
        IndentBlock,
        Italic,
        Paragraph,
        SelectAll,
        SpecialCharacters,
        Strikethrough,
        Subscript,
        Superscript,
        Table,
        TableCaption,
        TableCellProperties,
        TableColumnResize,
        TableProperties,
        TableToolbar,
        TextTransformation,
        Underline,
    ],
    table: {
        contentToolbar: ['tableColumn', 'tableRow', 'mergeTableCells', 'tableProperties', 'tableCellProperties'],
    },
};

export function inlineEditor(element) {
    if (!element) return;
    return new Promise((resolve, reject) => {
        InlineEditor.create(element, option)
            .then(editor => {
                resolve(editor);
            })
            .catch(error => {
                reject(error);
            });
    });
}

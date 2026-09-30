<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { Ckeditor } from '@ckeditor/ckeditor5-vue'
import { csrfHeader } from '../../api/client'
import {
  Alignment, Autoformat, BlockQuote, Bold, ClassicEditor, Essentials, FontBackgroundColor, FontColor, Heading,
  ImageBlock, ImageInsert, ImageResize, ImageStyle, ImageToolbar, ImageUpload, Indent, IndentBlock, Italic, Link,
  List, Paragraph, PasteFromOffice, RemoveFormat, SimpleUploadAdapter, Strikethrough, Subscript, Superscript,
  Table, TableCaption, TableCellProperties, TableColumnResize, TableProperties, TableToolbar, TextTransformation, Underline,
} from 'ckeditor5'

const props = defineProps<{ modelValue: string; uploadUrl?: string; readOnly?: boolean }>()
const emit = defineEmits<{ blur: [value: string]; 'update:modelValue': [value: string] }>()
const value = ref(props.modelValue)
const editor = ref<any>(null)
const config = computed(() => ({
  licenseKey: 'GPL',
  plugins: [Alignment, Autoformat, BlockQuote, Bold, Essentials, FontBackgroundColor, FontColor, Heading, ImageBlock, ImageInsert, ImageResize, ImageStyle, ImageToolbar, ImageUpload, Indent, IndentBlock, Italic, Link, List, Paragraph, PasteFromOffice, RemoveFormat, Strikethrough, Subscript, Superscript, SimpleUploadAdapter, Table, TableCaption, TableCellProperties, TableColumnResize, TableProperties, TableToolbar, TextTransformation, Underline],
  toolbar: { items: ['undo', 'redo', '|', 'heading', '|', 'fontColor', 'fontBackgroundColor', '|', 'bold', 'italic', 'underline', 'strikethrough', 'subscript', 'superscript', 'removeFormat', '|', 'alignment', 'bulletedList', 'numberedList', 'outdent', 'indent', '|', 'insertTable', 'tableProperties', 'tableCellProperties', '|', 'uploadImage', 'link', 'blockQuote'], shouldNotGroupWhenFull: true },
  table: { contentToolbar: ['tableColumn', 'tableRow', 'mergeTableCells', 'tableProperties', 'tableCellProperties'] },
  image: { styles: { options: ['alignBlockLeft', 'block', 'alignBlockRight'] }, resizeUnit: '%', resizeOptions: [{ name: 'resizeImage:original', value: null, label: '원본' }, { name: 'resizeImage:25', value: '25', label: '25%' }, { name: 'resizeImage:50', value: '50', label: '50%' }, { name: 'resizeImage:75', value: '75', label: '75%' }, { name: 'resizeImage:100', value: '100', label: '100%' }], toolbar: ['imageStyle:alignBlockLeft', 'imageStyle:block', 'imageStyle:alignBlockRight', '|', 'resizeImage'] },
  link: { addTargetToExternalLinks: true },
  simpleUpload: props.uploadUrl ? { uploadUrl: props.uploadUrl, headers: csrfHeader() } : undefined,
}) as any)
function ready(instance: any) { editor.value = instance; if (props.readOnly) instance.enableReadOnlyMode('app'); instance.ui.focusTracker.on('change:isFocused', (_event: unknown, _name: unknown, focused: boolean) => { if (!focused) emit('blur', instance.getData()) }) }
function changed(data: unknown) { value.value = String(data); emit('update:modelValue', value.value) }
watch(() => props.modelValue, next => { if (next !== value.value) { value.value = next; editor.value?.setData(next) } })
watch(() => props.readOnly, readonly => { if (!editor.value) return; readonly ? editor.value.enableReadOnlyMode('app') : editor.value.disableReadOnlyMode('app') })
</script>
<template><Ckeditor v-model="value" :editor="ClassicEditor" :config="config" :disabled="readOnly" @ready="ready" @update:model-value="changed" /></template>

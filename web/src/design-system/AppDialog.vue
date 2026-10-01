<script setup lang="ts">
import { DialogClose, DialogContent, DialogOverlay, DialogPortal, DialogRoot, DialogTitle } from 'reka-ui'

defineProps<{ title: string; wide?: boolean }>()
const open = defineModel<boolean>('open', { required: true })
</script>

<template>
  <DialogRoot v-model:open="open">
    <DialogPortal>
      <DialogOverlay class="app-dialog-overlay" />
      <DialogContent class="app-dialog-content" :class="{ 'app-dialog-content-wide': wide }">
        <header class="app-dialog-header"><DialogTitle>{{ title }}</DialogTitle><DialogClose class="app-dialog-close" aria-label="닫기">×</DialogClose></header>
        <div class="app-dialog-body"><slot /></div>
        <footer v-if="$slots.footer" class="app-dialog-footer"><slot name="footer" /></footer>
      </DialogContent>
    </DialogPortal>
  </DialogRoot>
</template>

<style scoped>
.app-dialog-overlay { position: fixed; inset: 0; z-index: 40; background: rgb(20 36 51 / .42); }.app-dialog-content { position: fixed; z-index: 41; top: 50%; left: 50%; width: min(680px, calc(100vw - 2rem)); max-height: calc(100vh - 2rem); overflow: auto; transform: translate(-50%, -50%); border-radius: var(--ex-radius-md); background: var(--ex-color-surface); box-shadow: var(--ex-shadow-lg); }.app-dialog-content-wide { width: min(1040px, calc(100vw - 2rem)); }.app-dialog-header,.app-dialog-footer { display: flex; align-items: center; justify-content: space-between; gap: var(--ex-space-3); padding: var(--ex-space-4); border-bottom: 1px solid var(--ex-color-border); }.app-dialog-header { font-weight: 700; }.app-dialog-footer { justify-content: flex-end; border-top: 1px solid var(--ex-color-border); border-bottom: 0; }.app-dialog-body { padding: var(--ex-space-4); }.app-dialog-close { display: inline-grid !important; width: 2rem; min-width: 2rem !important; height: 2rem; min-height: 2rem !important; place-items: center; border: 0 !important; border-radius: 50% !important; background: transparent !important; color: var(--ex-color-text-muted) !important; padding: 0 !important; font-size: 1.5rem; line-height: 1; }.app-dialog-close:hover:not(:disabled) { background: var(--ex-color-primary) !important; color: #fff !important; }
</style>

<script setup lang="ts">
import { DialogClose, DialogContent, DialogOverlay, DialogPortal, DialogRoot, DialogTitle } from 'reka-ui'

withDefaults(defineProps<{ title: string; side?: 'left' | 'right' }>(), { side: 'right' })
const open = defineModel<boolean>('open', { required: true })
</script>

<template>
  <DialogRoot v-model:open="open">
    <DialogPortal>
      <DialogOverlay class="app-drawer-overlay" />
      <DialogContent class="app-drawer-content" :class="`app-drawer-${side}`">
        <header class="app-drawer-header">
          <DialogTitle>{{ title }}</DialogTitle
          ><DialogClose class="app-drawer-close" aria-label="닫기">×</DialogClose>
        </header>
        <div class="app-drawer-body"><slot /></div>
        <footer v-if="$slots.footer" class="app-drawer-footer"><slot name="footer" /></footer>
      </DialogContent>
    </DialogPortal>
  </DialogRoot>
</template>

<style scoped>
.app-drawer-overlay {
  position: fixed;
  inset: 0;
  z-index: 40;
  background: rgb(20 36 51 / 0.42);
}
.app-drawer-content {
  position: fixed;
  z-index: 41;
  top: 0;
  bottom: 0;
  display: flex;
  flex-direction: column;
  width: min(440px, calc(100vw - 2rem));
  background: var(--ex-color-surface);
  box-shadow: var(--ex-shadow-lg);
}
.app-drawer-right {
  right: 0;
}
.app-drawer-left {
  left: 0;
}
.app-drawer-header,
.app-drawer-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--ex-space-3);
  padding: var(--ex-space-4);
  border-bottom: 1px solid var(--ex-color-border);
  font-weight: 700;
}
.app-drawer-footer {
  justify-content: flex-end;
  border-top: 1px solid var(--ex-color-border);
  border-bottom: 0;
}
.app-drawer-body {
  flex: 1;
  overflow: auto;
  padding: var(--ex-space-4);
}
.app-drawer-close {
  padding: 0;
  background: transparent;
  color: var(--ex-color-text-muted);
  font-size: 1.5rem;
  line-height: 1;
}
</style>

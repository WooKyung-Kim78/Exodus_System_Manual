<script setup lang="ts">
withDefaults(defineProps<{ emptyMessage?: string }>(), { emptyMessage: '표시할 항목이 없습니다.' })
defineSlots<{ default(): unknown; empty?(): unknown; footer?(): unknown }>()
</script>

<template>
  <div class="app-table-wrap"><table class="app-table"><slot /></table><div v-if="$slots.empty" class="app-table-empty"><slot name="empty" /></div><div v-if="$slots.footer" class="app-table-footer"><slot name="footer" /></div></div>
</template>

<style scoped>
.app-table-wrap { overflow-x:auto; overflow-y:hidden; -webkit-overflow-scrolling:touch; border:1px solid var(--ex-color-border); border-radius:var(--ex-radius); background:var(--ex-color-surface); }.app-table { width:100%; border:0; border-radius:0; }.app-table-empty { padding:var(--ex-space-6); text-align:center; color:var(--ex-color-text-muted); }.app-table-footer { display:flex; justify-content:flex-end; gap:var(--ex-space-2); padding:var(--ex-space-3); border-top:1px solid var(--ex-color-border); }
@media (max-width:680px) { .app-table { min-width:42rem; } }
</style>

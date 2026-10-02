<script setup lang="ts">
withDefaults(defineProps<{ variant?: 'primary' | 'secondary' | 'danger' | 'ghost' }>(), { variant: 'primary' })
</script>

<template>
  <button class="app-button" :class="`app-button--${variant}`"><slot /></button>
</template>

<style scoped>
.app-button {
  min-height: var(--ex-button-height);
  border: 1px solid transparent;
  border-radius: var(--ex-radius-sm);
  padding: 0.375rem var(--ex-space-3);
  cursor: pointer;
  font: inherit;
  font-size: var(--ex-button-font-size);
  font-weight: 600;
  transition:
    background-color 0.16s ease,
    border-color 0.16s ease;
}
.app-button:focus-visible {
  outline: 3px solid var(--ex-color-focus);
  outline-offset: 2px;
}
.app-button:disabled {
  cursor: not-allowed;
  opacity: 0.55;
}
.app-button--primary {
  background: var(--ex-color-primary);
  color: #fff;
}
.app-button--primary:hover:not(:disabled) {
  background: var(--ex-color-primary-hover);
}
.app-button--secondary {
  border-color: var(--ex-color-border);
  background: var(--ex-color-surface);
  color: var(--ex-color-text);
}
.app-button--secondary:hover:not(:disabled) {
  background: var(--ex-color-secondary);
}
.app-button--danger {
  background: var(--ex-color-danger);
  color: #fff;
}
.app-button--danger:hover:not(:disabled) {
  background: var(--ex-color-danger-hover);
}
.app-button--ghost {
  background: transparent;
  color: var(--ex-color-text-muted);
}
.app-button--ghost:hover:not(:disabled) {
  background: var(--ex-color-secondary);
  color: var(--ex-color-text);
}
</style>

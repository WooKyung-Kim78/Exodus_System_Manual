<script setup lang="ts">
defineProps<{ modelValue?: string }>()
defineEmits<{ 'update:modelValue': [value: string] }>()
</script>

<template>
  <input
    class="app-input"
    :value="modelValue"
    @input="$emit('update:modelValue', ($event.target as HTMLInputElement).value)"
  />
</template>

<style scoped>
.app-input {
  width: 100%;
  border: 1px solid var(--ex-color-border-strong);
  border-radius: var(--ex-radius-sm);
  padding: var(--ex-space-2);
  background: var(--ex-color-surface);
  color: var(--ex-color-text);
  font: inherit;
}
.app-input:focus {
  border-color: var(--ex-color-primary);
  outline: 3px solid var(--ex-color-focus);
}
</style>

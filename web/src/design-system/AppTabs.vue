<script setup lang="ts">
export interface TabItem {
  id: string
  label: string
  disabled?: boolean
}

defineProps<{ items: TabItem[] }>()
const selected = defineModel<string>({ required: true })
</script>

<template>
  <div class="app-tabs" role="tablist" aria-label="탭">
    <button
      v-for="item in items"
      :key="item.id"
      class="app-tab"
      :class="{ selected: selected === item.id }"
      type="button"
      role="tab"
      :aria-selected="selected === item.id"
      :disabled="item.disabled"
      @click="selected = item.id"
    >
      {{ item.label }}
    </button>
  </div>
</template>

<style scoped>
.app-tabs {
  display: flex;
  gap: var(--ex-space-1);
  border-bottom: 1px solid var(--ex-color-border);
}
.app-tab {
  border-radius: var(--ex-radius-sm) var(--ex-radius-sm) 0 0;
  background: transparent;
  color: var(--ex-color-text-muted);
}
.app-tab.selected {
  color: var(--ex-color-primary);
  box-shadow: inset 0 -2px var(--ex-color-primary);
}
</style>

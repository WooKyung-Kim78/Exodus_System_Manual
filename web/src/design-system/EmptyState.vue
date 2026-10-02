<script setup lang="ts">
defineProps<{ title: string; description?: string }>()
</script>

<template>
  <div class="empty-state">
    <h2>{{ title }}</h2>
    <p v-if="description">{{ description }}</p>
    <slot />
  </div>
</template>

<style scoped>
.empty-state {
  display: grid;
  justify-items: center;
  gap: var(--ex-space-2);
  padding: var(--ex-space-8);
  border: 1px dashed var(--ex-color-border-strong);
  border-radius: var(--ex-radius);
  color: var(--ex-color-text-muted);
  text-align: center;
}
.empty-state h2,
.empty-state p {
  margin: 0;
}
.empty-state h2 {
  color: var(--ex-color-text);
  font-size: 1rem;
}
</style>

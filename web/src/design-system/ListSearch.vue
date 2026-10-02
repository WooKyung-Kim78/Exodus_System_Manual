<script setup lang="ts">
import AppIcon from './AppIcon.vue'

defineProps<{ placeholder: string; label: string }>()
const keyword = defineModel<string>({ required: true })
const emit = defineEmits<{ search: [] }>()
</script>

<template>
  <form class="list-search" @submit.prevent="emit('search')">
    <input v-model="keyword" :aria-label="label" :placeholder="placeholder" /><button
      class="secondary"
      type="submit"
      :aria-label="label"
    >
      <AppIcon name="magnify" />
    </button>
  </form>
</template>

<style scoped>
.list-search {
  display: flex;
  min-width: min(100%, 28rem);
  flex-wrap: nowrap;
  align-items: center;
  gap: var(--ex-space-2);
}
.list-search input {
  flex: 1;
  min-width: 0;
}
.list-search button {
  display: inline-grid;
  width: var(--ex-control-height);
  min-width: var(--ex-control-height);
  height: var(--ex-control-height);
  min-height: var(--ex-control-height);
  flex: 0 0 auto;
  place-items: center;
  padding: 0;
  font-size: var(--ex-control-font-size);
}
.list-search :deep(.app-icon) {
  font-size: 1rem;
}
</style>

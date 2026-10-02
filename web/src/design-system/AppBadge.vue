<script setup lang="ts">
import { computed } from 'vue'
import { getManualStatus } from '../features/manual/status'

type BadgeTone = 'neutral' | 'warning' | 'success' | 'info' | 'danger'

const props = defineProps<{ status?: string; label?: string; tone?: BadgeTone }>()
const item = computed(() =>
  props.label ? { label: props.label, tone: props.tone ?? 'neutral' } : getManualStatus(props.status ?? ''),
)
</script>

<template>
  <span class="app-badge" :class="`app-badge--${item.tone}`">{{ item.label }}</span>
</template>

<style scoped>
.app-badge {
  display: inline-flex;
  white-space: nowrap;
  border-radius: 999px;
  padding: 0.2rem 0.5rem;
  font-size: 0.75rem;
  font-weight: 700;
}
.app-badge--neutral {
  background: var(--ex-color-neutral-subtle);
  color: var(--ex-color-text-muted);
}
.app-badge--warning {
  background: var(--ex-color-warning-subtle);
  color: var(--ex-color-warning);
}
.app-badge--success {
  background: var(--ex-color-success-subtle);
  color: var(--ex-color-success);
}
.app-badge--info {
  background: var(--ex-color-info-subtle);
  color: var(--ex-color-info);
}
.app-badge--danger {
  background: var(--ex-color-danger-subtle);
  color: var(--ex-color-danger);
}
</style>

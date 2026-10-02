<script setup lang="ts">
import { onBeforeUnmount, watch } from 'vue'

const props = withDefaults(defineProps<{ message: string; type?: 'success' | 'error' | 'info'; duration?: number }>(), {
  type: 'info',
  duration: 4000,
})
const open = defineModel<boolean>('open', { required: true })
let timer: ReturnType<typeof setTimeout> | undefined

function clearTimer() {
  if (timer) clearTimeout(timer)
  timer = undefined
}
watch(open, (visible) => {
  clearTimer()
  if (visible && props.duration > 0)
    timer = setTimeout(() => {
      open.value = false
    }, props.duration)
})
onBeforeUnmount(clearTimer)
</script>

<template>
  <div v-if="open" class="app-toast" :class="`app-toast-${type}`" role="status">
    <span>{{ message }}</span
    ><button type="button" aria-label="알림 닫기" @click="open = false">×</button>
  </div>
</template>

<style scoped>
.app-toast {
  position: fixed;
  z-index: 60;
  right: var(--ex-space-4);
  bottom: var(--ex-space-4);
  display: flex;
  align-items: center;
  gap: var(--ex-space-3);
  max-width: min(420px, calc(100vw - 2rem));
  border-radius: var(--ex-radius);
  padding: var(--ex-space-3) var(--ex-space-4);
  box-shadow: var(--ex-shadow-lg);
}
.app-toast-info {
  background: var(--ex-color-info-subtle);
  color: var(--ex-color-info);
}
.app-toast-success {
  background: var(--ex-color-success-subtle);
  color: var(--ex-color-success);
}
.app-toast-error {
  background: var(--ex-color-danger-subtle);
  color: var(--ex-color-danger);
}
.app-toast button {
  padding: 0;
  background: transparent;
  color: inherit;
  font-size: 1.25rem;
}
</style>

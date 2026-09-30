<script setup lang="ts">
import AppDialog from './AppDialog.vue'

defineProps<{ title?: string; message: string; confirmLabel?: string; danger?: boolean }>()
const open = defineModel<boolean>('open', { required: true })
const emit = defineEmits<{ confirm: []; cancel: [] }>()

function confirm() {
  open.value = false
  emit('confirm')
}

function cancel() {
  open.value = false
  emit('cancel')
}
</script>

<template>
  <AppDialog v-model:open="open" :title="title ?? '확인'">
    <p>{{ message }}</p>
    <template #footer>
      <button class="secondary" type="button" @click="cancel">취소</button>
      <button :class="{ danger }" type="button" @click="confirm">{{ confirmLabel ?? '확인' }}</button>
    </template>
  </AppDialog>
</template>

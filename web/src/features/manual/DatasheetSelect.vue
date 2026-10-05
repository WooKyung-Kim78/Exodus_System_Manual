<script setup lang="ts">
import { computed, ref } from 'vue'
import AppIcon from '../../design-system/AppIcon.vue'
import type { DatasheetOption } from '../../api/types'

const props = withDefaults(defineProps<{ options: DatasheetOption[]; disabled?: boolean; placeholder?: string }>(), {
  disabled: false,
  placeholder: 'Model Name 검색 (datasheet)',
})
const modelValue = defineModel<string>({ default: '' })
const emit = defineEmits<{ select: [item: DatasheetOption | null] }>()
const keyword = ref('')
const open = ref(false)

const filtered = computed(() => {
  const term = keyword.value.trim().toLowerCase()
  const matched = term
    ? props.options.filter((item) => item.NAME.toLowerCase().includes(term) || item.TITLE?.toLowerCase().includes(term))
    : props.options
  return matched.slice(0, 50)
})

function focus() {
  if (!props.disabled) {
    keyword.value = ''
    open.value = true
  }
}
function input(event: Event) {
  keyword.value = (event.target as HTMLInputElement).value
  open.value = true
}
function blur() {
  window.setTimeout(() => {
    open.value = false
    keyword.value = ''
  }, 150)
}
function select(item: DatasheetOption) {
  modelValue.value = item.NAME
  emit('select', item)
  open.value = false
  keyword.value = ''
}
function clear() {
  if (!props.disabled) {
    modelValue.value = ''
    emit('select', null)
    open.value = false
    keyword.value = ''
  }
}
</script>

<template>
  <div class="datasheet-select">
    <div class="datasheet-select-control">
      <input
        :value="open ? keyword : modelValue"
        :disabled="disabled"
        :placeholder="placeholder"
        autocomplete="off"
        @focus="focus"
        @input="input"
        @blur="blur"
        @keydown.esc="open = false"
      />
      <button v-if="!disabled" type="button" aria-label="Model Name 지우기" title="지우기" @mousedown.prevent="clear">
        <AppIcon name="close" />
      </button>
    </div>
    <div v-if="open" class="datasheet-select-options">
      <p v-if="filtered.length === 0">검색 결과가 없습니다.</p>
      <button v-for="item in filtered" v-else :key="item.D_ID" type="button" @mousedown.prevent="select(item)">
        <span
          ><strong>{{ item.NAME }}</strong
          ><small v-if="item.DS_VERSION">Rev {{ item.DS_VERSION }}</small></span
        >
        <em v-if="item.TITLE">{{ item.TITLE }}</em>
      </button>
    </div>
  </div>
</template>

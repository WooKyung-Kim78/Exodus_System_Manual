<script setup lang="ts">
defineProps<{ name: string; label?: string }>()
</script>

<template>
  <i class="app-icon mdi" :class="`mdi-${name}`" :aria-hidden="label ? undefined : 'true'" :aria-label="label" />
</template>

<style scoped>
.app-icon {
  display: inline-block;
  font-style: normal;
  line-height: 1;
}
</style>

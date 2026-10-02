<script setup lang="ts">
defineProps<{ title: string }>()
</script>

<template>
  <section class="list-card">
    <header class="list-card-header">
      <h2>{{ title }}</h2>
      <div v-if="$slots['header-actions']" class="list-card-header-actions"><slot name="header-actions" /></div>
    </header>
    <div v-if="$slots.filters || $slots.search" class="list-card-toolbar">
      <div v-if="$slots.filters" class="list-card-filters"><slot name="filters" /></div>
      <div v-if="$slots.search" class="list-card-search"><slot name="search" /></div>
    </div>
    <div class="list-card-content"><slot /></div>
  </section>
</template>

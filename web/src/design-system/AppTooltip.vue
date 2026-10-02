<script setup lang="ts">
import { TooltipContent, TooltipPortal, TooltipProvider, TooltipRoot, TooltipTrigger } from 'reka-ui'

defineProps<{ text: string }>()
</script>

<template>
  <TooltipProvider>
    <TooltipRoot>
      <TooltipTrigger as-child><slot /></TooltipTrigger>
      <TooltipPortal
        ><TooltipContent class="app-tooltip" :side-offset="6">{{ text }}</TooltipContent></TooltipPortal
      >
    </TooltipRoot>
  </TooltipProvider>
</template>

<style scoped>
.app-tooltip {
  z-index: 50;
  border-radius: var(--ex-radius-sm);
  background: var(--ex-color-text);
  color: white;
  padding: var(--ex-space-2) var(--ex-space-3);
  font-size: 0.8rem;
  box-shadow: var(--ex-shadow);
}
</style>

<template>
  <li class="ml-0! text-xs">
    <sup v-if="number">{{ number }}</sup>
    <slot />
  </li>
</template>

<script setup lang="ts">
defineProps<{
  number?: number;
}>();
</script>

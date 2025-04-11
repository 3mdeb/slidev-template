<template>
  <div>
    <Scroll />
    <footer
      v-if="$nav.currentLayout !== 'cover'"
      class="absolute bottom-0 left-0 right-0 flex justify-between items-center py-2 text-[#000000]"
    >
      <small class="mx-auto"
        >© Copyright 2025. All Rights Reserved by 3mdeb Sp. z o.o.</small
      >
      <small class="mr-4">{{ $nav.currentPage }}</small>
    </footer>
  </div>
</template>

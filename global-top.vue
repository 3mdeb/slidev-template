<template>
  <div class="slide-body">
    <Scroll />
    <footer
      v-if="$nav.currentLayout !== 'cover'"
      class="absolute bottom-0 left-0 right-0 flex justify-between items-center py-2 text-[#000000]"
    >
      <small
        v-if="$slidev.configs.copyright && $slidev.configs.copyright.length !== 0"
        class="mx-auto"
        >© Copyright {{ new Date().getFullYear() }}. {{ $slidev.configs.copyright }}</small
      >
      <small v-else class="mx-auto"></small>
      
      <small class="mr-4"><SlideCurrentNo/>/<SlidesTotal/></small>
    </footer>
  </div>
</template>

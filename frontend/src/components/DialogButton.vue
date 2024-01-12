<script>
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import { ref } from 'vue'

export default {
  emits: ['close', 'open'],
  inheritAttrs: false,
  props: {
    breakpoints: {
      type: Object,
      default: {
        '960px': '75vw',
        '640px': '90vw'
      }
    }
  },
  setup(_props, { emit }) {
    const visible = ref(false)

    const onOpen = () => {
      visible.value = true
      emit('open')
    }
    const close = () => {
      visible.value = false
      emit('close')
    }
    return {
      visible,
      onOpen
    }
  },
  components: {
    Button,
    Dialog
  }
}

</script>
<template>
  <Button v-bind="$attrs" @click="onOpen"/>
  <Dialog
    v-model:visible="visible"
    :modal="true"
    class="p-confirm-dialog"
    :closeOnEscape="true"
    :breakpoints="breakpoints"
  >
    <template v-for="(_, name) in $slots" v-slot:[name]="slotProps">
      <slot v-if="slotProps" :name="name" v-bind="slotProps" />
      <slot v-else :name="name" />
    </template>
  </Dialog>
</template>
<style>
/* Broken close button alignment fix */
.p-dialog-header .p-dialog-header-icons {
  margin-left: auto;
}
</style>

<script>
// TODO: Could possibly be refactored using dialogButton
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import Button from 'primevue/button'
import { ref } from 'vue'

export default {
  emits: ['accept', 'close', 'open'],
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
    const onAccept = () => {
      emit('accept', close)
    }
    const onDecline = () => {
      close()
    }

    return {
      visible,
      onOpen,
      onAccept,
      onDecline
    }
  },
  components: {
    Button,
    ConfirmDialog
  }
}

</script>
<template>
  <Button v-bind="$attrs" @click="onOpen"/>
  <ConfirmDialog v-model:visible="visible" @open="onOpen" @accept="onAccept" @decline="onDecline">
    <template v-for="(_, name) in $slots" v-slot:[name]="slotProps">
      <slot v-if="slotProps" :name="name" v-bind="slotProps" />
      <slot v-else :name="name" />
    </template>
  </ConfirmDialog>
</template>

<style>
/* Broken close button alignment fix */
.p-dialog-header .p-dialog-header-icons {
  margin-left: auto;
}
</style>

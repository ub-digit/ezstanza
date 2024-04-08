<script>
// TODO: Could possibly be refactored using dialogButton
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import { ref } from 'vue'

export default {
  emits: ['accept', 'decline', 'close', 'update:visible'],
  inheritAttrs: false,
  props: {
    breakpoints: {
      type: Object,
      default: {
        '960px': '75vw',
        '640px': '90vw'
      }
    },
    visible: {
      type: Boolean,
      default: false
    }
  },
  setup(_props, { emit }) {
    const loading = ref(false)

    const close = () => {
      loading.value = false
      emit('update:visible', false)
      emit('close')
    }
    const onAccept = () => {
      loading.value = true
      emit('accept', close)
    }
    const onDecline = () => {
      emit('decline')
      close()
    }

    return {
      loading,
      onAccept,
      onDecline
    }
  },
  components: {
    Button,
    Dialog
  }
}

</script>
<template>
  <Dialog :visible="visible" @update:visible="$emit('update:visible', $event)" :modal="true" class="p-confirm-dialog" :closeOnEscape="true" :breakpoints="breakpoints">
    <template #header>
      <slot name="header"></slot>
    </template>
    <template #default>
      <slot></slot>
    </template>
    <template #footer>
      <Button label="Yes" @click="onAccept"  :autofocus="true" :disabled="loading"/>
      <Button label="No" @click="onDecline" class="p-button-text" :disabled="loading"/>
    </template>
  </Dialog>
</template>

<style>
/* Broken close button alignment fix */
.p-dialog-header .p-dialog-header-icons {
  margin-left: auto;
}
</style>

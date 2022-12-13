<script>
import Dialog from 'primevue/dialog'
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
    const loading = ref(false)

    const onOpen = () => {
      visible.value = true
      emit('open')
    }
    const close = () => {
      visible.value = false
      loading.value = false
      emit('close')
    }
    const onAccept = () => {
      loading.value = true
      emit('accept', close)
    }
    const onDecline = () => {
      close()
    }

    return {
      visible,
      loading,
      onOpen,
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
  <Button v-bind="$attrs" @click="onOpen"/>
  <Dialog v-model:visible="visible" :modal="true" class="p-confirm-dialog" :closeOnEscape="true" :breakpoints="breakpoints">
    <template #header>
      <slot name="header"></slot>
    </template>
    <template #default>
      <slot></slot>
    </template>
    <template #footer>
      <Button label="No" @click="onDecline" class="p-button-text" :disabled="loading"/>
      <Button label="Yes" @click="onAccept"  :autofocus="true" :disabled="loading"/>
    </template>
  </Dialog>
</template>

<style>
/* Broken close button alignment fix */
.p-dialog-header .p-dialog-header-icons {
  margin-left: auto;
}
</style>

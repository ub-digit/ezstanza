<script>
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import { ref } from 'vue'

export default {
  emits: ['close', 'open'],
  inheritAttrs: false,
  props: {
    // TODO: Hack to fix overflow issue for datatables
    // don't really know the root cause and have not found others
    // who have the same issue!?
    overflowFix: {
      type: Boolean,
      default: false
    },
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
    class="p-confirm-dialog"
    :breakpoints="breakpoints"
    :contentStyle="overflowFix ? 'display: block;' : null"
    modal
    closeOnEscape
    maximizable
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

<script>
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import {inject, ref, toRefs } from 'vue'

export default {
  emits: ['accept'],
  inheritAttrs: false,
  props: {
    stanza: {
      type: Object,
      required: true
    },
    breakpoints: {
      type: Object,
      default: null
    }
  },
  setup( props, { emit }) {
    const visible = ref(false)
    const loading = ref(false)

    const api = inject('api')

    const { stanza } = toRefs(props)

    const stanzaRevisions = ref()

    const onOpen = async () => {
      visible.value = true
      const result = await api.stanzas.fetch(stanza.value.id, { include: "revisions" })
      console.log('onOpen result:')
      console.dir(result)
      //stanzaRevisions.value = result.data.stanza_revisions
    }
    const close = () => {
      visible.value = false
      loading.value = false
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
      onDecline,
      stanzaRevisions
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
      Select stanza revision
    </template>
    <template #default>
      <pre>{{ stanzaRevisions }}</pre>
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

<script>
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import Dropdown from 'primevue/dropdown';
import {inject, ref, toRef, toRefs } from 'vue'

export default {
  emits: ['accept'],
  inheritAttrs: false,
  props: {
    currentRevision: {
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
    const loading = ref(true)

    const currentRevision = toRef(props, 'currentRevision');

    const selectedRevision = ref(currentRevision.value)
    const revisions = ref()

    const dayjs = inject('dayjs')
    const api = inject('api')

    const onOpen = async () => {
      visible.value = true
      const result = await api.stanza_revisions.list({ stanza_id: selectedRevision.value.stanza_id })
      revisions.value = result.data
      loading.value = false
    }
    const close = () => {
      visible.value = false
      loading.value = false
    }
    const onAccept = () => {
      emit('accept', selectedRevision)
      close()
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
      revisions,
      selectedRevision,
      dayjs,
      loading
    }
  },
  components: {
    Button,
    Dialog,
    Dropdown
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
      <div class="flex flex-column">
        <Dropdown :loading="loading" v-model="selectedRevision" dataKey="id" :options="revisions">
          <template #option="{ option }">
            <span :class="{'text-green-700': option.is_current_revision}">
              Revision: {{ option.id }} ({{ dayjs(option.updated_at).format('L LT') }})
            </span>
          </template>
          <template #value="{ value }">
            <span :class="{'text-green-700': value.is_current_revision}">
              Revision: {{ value.id }} ({{ dayjs(value.updated_at).format('L LT') }})
            </span>
          </template>
        </Dropdown>
      </div>
    </template>
    <template #footer>
      <Button label="Cancel" @click="onDecline" class="p-button-text" :disabled="loading"/>
      <Button label="Change" @click="onAccept"  :autofocus="true" :disabled="loading"/>
    </template>
  </Dialog>
</template>

<style>
/* Broken close button alignment fix */
.p-dialog-header .p-dialog-header-icons {
  margin-left: auto;
}
</style>

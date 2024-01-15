<script>
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import { ref, toRaw, reactive, inject } from 'vue'

import StanzaRevisionSelect from '@/components/StanzaRevisionSelect.vue'

export default {
  emits: ['update:modelValue', 'update:selected'],
  inheritAttrs: false,
  props: {
    breakpoints: {
      type: Object,
      default: {
        '960px': '75vw',
        '640px': '90vw'
      }
    },
    label: {
      type: String,
      default: "Add stanza revisions"
    },
    modelValue: {
      type: Array,
      required: true
    },
    selected: { //TODO: naming, selectedStanzaRevions, make constent with child component
      type: Array,
      default: []
    },
    params: {
      type: Object,
      default: {}
    }
  },
  setup(props, { emit }) {
    const loading = ref(false) //TODO: true?
    const dialogVisible = ref(false)
    const openDialog = () => {
      dialogVisible.value = true
    }

    //const selectedStanzaRevisions = ref([])

    const onAddStanzaRevisions = () => {
      dialogVisible.value = false
      //emit('update:modelValue', toRaw(props.selectedStanzaRevisions.value)) //TODO: toRaw to be consistent, but wtf?
      emit('update:modelValue', toRaw(props.selected)) //TODO: toRaw to be consistent, but wtf?
    }

    return {
      dialogVisible,
      openDialog,
      //selectedStanzaRevisions,
      onAddStanzaRevisions,
      loading
    }
  },
  components: {
    Button,
    Dialog,
    StanzaRevisionSelect
  }
}

</script>
<template>
  <Button @click="openDialog" v-bind="$attrs" :label="label"/>
  <Dialog modal closable closeOnEscape v-model:visible="dialogVisible" class="p-confirm-dialog" :breakpoints="breakpoints">
    <template #header>
      Select stanza revisions
    </template>

    <template #default>
      <StanzaRevisionSelect
        :params="params"
        :modelValue="selected"
        @update:modelValue="$emit('update:selected', $event)"
        v-model:loading="loading"
      />
    </template>
   <template #footer>
      <Button label="Add" @click="onAddStanzaRevisions" :autofocus="true" :disabled="loading"/>
    </template>
  </Dialog>
</template>
<style>
</style>

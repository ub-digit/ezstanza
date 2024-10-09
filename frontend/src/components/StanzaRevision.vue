<script>
import Tag from 'primevue/tag'
import { ref, computed } from 'vue'
import Button from 'primevue/button'
import Dialog from 'primevue/dialog'
import SelectButton from 'primevue/selectbutton'
import SplitButton from 'primevue/splitbutton'
import ConfirmDialogButton from '@/components/ConfirmDialogButton.vue'

export default {
  emits: ['revert'],
  props: {
    stanzaRevision: {
      type: Object,
      required: true
    },
    currentStanzaRevision: {
      type: Object,
      required: true
    },
    previousStanzaRevision: {
      type: Object
    },
  },
  setup(props) {
    const diffDialogVisible = ref(false)
    const stanzaDialogVisible = ref(false)

    const diffMode = ref({ name: 'Unified', value: 'unified' })
    const diffModeOptions = ref([
      { name: 'Unified', value: 'unified' },
      { name: 'Split', value: 'split' }
    ])

    const previousRevisionBody = props.previousStanzaRevision ? props.previousStanzaRevision.body : ''

    const diffTarget = ref(previousRevisionBody)

    const diffAgainstPrevious = () => {
      diffTarget.value = previousRevisionBody
      diffDialogVisible.value = true
    }

    const diffOptions = [
      {
        label: 'Previous revision',
        icon: 'pi pi-copy',
        command: diffAgainstPrevious
      },
      {
        label: 'Current revision',
        icon: 'pi pi-copy',
        command: () => {
          diffTarget.value = props.currentStanzaRevision.body
          diffDialogVisible.value = true
        }
      }
    ]

    return {
      diffMode,
      diffModeOptions,
      diffOptions,
      diffAgainstPrevious,
      diffTarget,
      diffDialogVisible,
      stanzaDialogVisible,
    }
  },
  components: {
    Dialog,
    Button,
    SplitButton,
    SelectButton,
    ConfirmDialogButton,
    Tag
  }
}

</script>
<template>
  <div class="flex flex-row" :class="{ 'is-current-revision': stanzaRevision.is_current_revision}">
    <div class="flex flex-auto flex-column p-4 gap-2">
      <span>
        <Button size="small" icon="pi pi-file" severity="primary" @click="stanzaDialogVisible = true" :label="'Revision: ' + stanzaRevision.id"/>
      </span>
      <span>{{ stanzaRevision.log_message }}</span>
      <span><span class="revision-user">{{ stanzaRevision.user.name }}</span><span class="revision-updated-at"> updated on {{ stanzaRevision.updated_at }}</span></span>
    </div>
    <div class="flex flex-column justify-content-center p-4 gap-2">
      <Dialog
        v-model:visible="stanzaDialogVisible"
        modal
        :draggable="false"
        :style="{ width: '90vw' }"
      >
        <pre>{{ stanzaRevision.body }}</pre>
      </Dialog>

      <Button
        size="small"
        v-if="stanzaRevision.is_current_revision"
        label="View changes"
        icon="pi pi-copy"
        severity="secondary"
        @click="diffAgainstPrevious"
      />
      <SplitButton
        v-else
        size="small"
        label="View changes"
        icon="pi pi-copy"
        severity="secondary"
        @click="diffAgainstPrevious"
        :model="diffOptions"
      />
      <Dialog
        v-model:visible="diffDialogVisible"
        :draggable="false"
        modal
        :style="{ width: '90vw' }"
      >
        <template #header>
          <SelectButton
            v-model="diffMode"
            :options="diffModeOptions"
            optionLabel="name"
            aria-labelledby="basic"
          />
        </template>
        <VueDiff
          :mode="diffMode.value"
          theme="light"
          :prev="diffTarget"
          :current="stanzaRevision.body"
        />
      </Dialog>
      <ConfirmDialogButton
        v-if="!stanzaRevision.is_current_revision"
        size="small"
        label="Revert to"
        icon="pi pi-history"
        severity="help"
        @accept="$emit('revert', stanzaRevision, $event)"
      >
        <!-- break out into component? -->
        <i class="pi pi-exclamation-triangle mr-3 p-confirm-dialog-icon"/>
        <template #header>
          Confirm revertion
        </template>
        <span class="p-confirm-dialog-message">
          Are you sure you want to revert to revision {{ stanzaRevision.id }}?
        </span>
      </ConfirmDialogButton>
      <!--
      <Button
        v-if="!stanzaRevision.is_current_revision"
        size="small"
        label="Revert to"
        icon="pi pi-history"
        severity="help"
        @click="$emit('revert', stanzaRevision)"
      />
      -->
    </div>
  </div>

</template>
<style>
.revision-user {
  font-weight: bold;
}
.revision-updated-at {
  color: rgb(101, 109, 118);
}
.is-current-revision {
  background-color: rgb(234, 255, 227);
}
</style>

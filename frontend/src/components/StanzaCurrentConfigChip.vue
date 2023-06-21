<script>
//import Chip from '@/components/Chip.vue'
import ColorChip from '@/components/ColorChip.vue'
import useTextClassForBackground from '@/components/UseTextClassForBackground.js' //BackgroundColor?
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'
import OverlayPanel from 'primevue/overlaypanel'
import Tag from 'primevue/tag'
import { ref, inject } from 'vue';
export default {
  inheritAttrs: false,
  props: {
    currentConfig: {
      type: Object,
      required: true
    },
    modalBreakpoints: {
      type: Object,
      default: {
        '1200px': '60vw',
        '1024px': '75vw',
        '720px': '90vw'
      }
    },
  },
  setup({ currentConfig }, { emit }) {

    const dayjs = inject('dayjs')
    const configStanzaInfo = ref(null)

    const toggleConfigStanzaInfo = (event) => {
      configStanzaInfo.value.toggle(event)
    }

    //TODO: Get deploy targets, check if deployed in current deployment, and allow user to view
    //diff from currently deployed config
    const onRemove = (event) => {
      modalIsVisible.value = true
    }
    //const onRemoved??
    const onConfirmRemove = () => {
      console.log('confirm remove')
      chipIsVisible.value = false
      modalIsVisible.value = false
      emit('removeConfig', currentConfig)
    }
    const onConfirmRemoveAndDeploy = () => {
      console.log('confirm remove deploy')
      chipIsVisible.value = false
      deploymentFormIsVisible.value = true
    }
    const textColorClass = useTextClassForBackground(currentConfig.color, 'text-black', 'text-white')
    const modalIsVisible = ref(false)
    const chipIsVisible = ref(true)
    const deploymentFormIsVisible = ref(false)

    return {
      textColorClass,
      modalIsVisible,
      chipIsVisible,
      deploymentFormIsVisible,
      onRemove,
      onConfirmRemove,
      onConfirmRemoveAndDeploy,
      configStanzaInfo,
      toggleConfigStanzaInfo,
      dayjs
    }
  },
  components: {
    ColorChip,
    Dialog,
    Button,
    OverlayPanel,
    Tag
  }
}
</script>
<template>
  <ColorChip
    :key="currentConfig.id"
    :visible="chipIsVisible"
    :color="currentConfig.color"
    removable
    @remove="onRemove"
    v-bind="$attrs"
  >
  <i :class="['pi', currentConfig.has_current_stanza_revision ? 'pi-check' : 'pi-info-circle', 'stanza-info']" @mouseover="toggleConfigStanzaInfo" @mouseleave="toggleConfigStanzaInfo"></i>
    <OverlayPanel ref="configStanzaInfo">
      <div class="flex flex-column align-items-start gap-2">
        <template v-if="currentConfig.has_current_stanza_revision">
          <Tag icon="pi pi-check-circle" severity="success">
            Current revision
          </Tag>
        </template>
        <template v-else>
          <!--<Tag icon="pi pi-file" severity="info" :style="{ 'background-color': '#dee2e6', color: '#495057' }"> -->
          <Tag icon="pi pi-file" severity="info">
            Revision id: {{ currentConfig.stanza_revision.id }}
          </Tag>
          <div v-if="currentConfig.stanza_revision.log_message" class="text-sm">
            {{ currentConfig.stanza_revision.log_message }}
          </div>
          <span class="text-xs">
            By: {{ currentConfig.stanza_revision.user.name }}<br/>
            {{ dayjs(currentConfig.stanza_revision.updated_at).format('L LT') }}
          </span>
        </template>
      </div>
    </OverlayPanel>
    <span class="ml-2 p-chip-text">{{ currentConfig.name }}</span>
  </ColorChip>
  <Dialog v-if="!deploymentFormIsVisible" v-model:visible="modalIsVisible" modal header="Remove from current config" :style="{ width: '50vw' }" :breakpoints="modalBreakpoints">
    <span>Remove <span class="font-bold">{{currentConfig.stanza_revision.name }}</span> from {{ currentConfig.name }}?</span>
    <template #footer>
      <Button label="Remove" icon="pi pi-trash" @click="onConfirmRemove" autofocus />
      <Button label="Remove and deploy" icon="pi pi-arrow-circle-right" @click="onConfirmRemoveAndDeploy" />
    </template>
  </Dialog>
  <Dialog v-else v-model:visible="modalIsVisible" modal header="Deploy configs" :style="{ width: '50vw' }" :breakpoints="modalBreakpoints">
    <template #footer>
      <Button label="Deploy" icon="pi pi-cloud-upload" @click="onConfirmRemove" autofocus />
    </template>
  </Dialog>
</template>
<style lang="scss" scoped>
.stanza-info {
  cursor: pointer;
}
.p-chip.has-previous-revision .stanza-info {
  opacity: 0.4;
}
</style>

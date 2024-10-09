<script>
import { computed, watch, ref, inject, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import DataView from 'primevue/dataview'
import DataViewLayoutOptions from 'primevue/dataviewlayoutoptions'
import StanzaRevision from '@/components/StanzaRevision.vue'
import { useStanzaRevisionsStore } from '@/stores/stanzaRevisions.js'
import { storeToRefs } from 'pinia'

export default {
  setup() {
    const api = inject('api')
    const store = useStanzaRevisionsStore()
    const { currentStanzaRevision, stanzaRevisionsWithPrevious } = storeToRefs(store)
    const route = useRoute()
    watch(
      () => route.params.id,
      async newId => {
        // Triggered when leaving route, WTF!?!?
        if (typeof newId !== 'undefined') {
          await store.fetchStanzaRevisions(newId) //await?
        }
      },
      { immediate: true }
    )

    const revertToRevision = async (stanzaRevision, closeDialog) => {
      const result = await api.stanzas.fetch(store.stanzaId)
      const stanza = result.data
      stanza.body = stanzaRevision.body
      stanza.log_message = `Reverted from revision ${stanzaRevision.id}: ${stanzaRevision.log_message}`
      delete stanza.current_deployments
      await api.stanzas.update(stanza.id, stanza)
      await store.fetchStanzaRevisions()
      closeDialog()
    }

    return {
      currentStanzaRevision,
      stanzaRevisionsWithPrevious,
      revertToRevision
    }
  },
  components: {
    DataView,
    StanzaRevision
  }
}
</script>
<template>
  <DataView :value="stanzaRevisionsWithPrevious" paginator :rows="10">
    <template #list="slotProps">
      <div class="col-12">
        <StanzaRevision
          :stanzaRevision="slotProps.data.revision"
          :currentStanzaRevision="currentStanzaRevision"
          :previousStanzaRevision="slotProps.data.previousRevision"
          @revert="revertToRevision"
        />
      </div>
    </template>
  </DataView>
</template>

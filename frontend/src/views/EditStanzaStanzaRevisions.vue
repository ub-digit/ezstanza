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

    const { currentStanzaRevision } = storeToRefs(store)

    const stanzaRevisionsWithPrevious = computed(() => {
      const result = []

      if (store.stanzaRevisions.length) {
        const lastIndex = store.stanzaRevisions.length - 1

        if (lastIndex > 0) {
          for(let i = 0; i < lastIndex; ++i) {
            result.push({
              revision: store.stanzaRevisions[i],
              previousRevision: store.stanzaRevisions[i + 1]
            })
          }
        }
        result.push({
          revision: store.stanzaRevisions[lastIndex]
        })
      }
      return result
    })

    const route = useRoute()
    //const currentStanzaRevision = ref()
    //const stanzaRevisions = ref([])
    watch(
      () => route.params.id,
      async newId => {
        // Triggered when leaving route, WTF!?!?
        if (typeof newId !== 'undefined') {
          store.stanzaId = newId
          await store.fetchStanzaRevisions() //await?
          /*
          //TODO: error handling
          stanzaRevisions.value = []
          // TODO: Ensure ordered by id?
          const currentRevisionResult = await api.stanza_revisions.list(
            {
              stanza_id: newId,
              is_current_revision: true
            }
          )
          currentStanzaRevision.value = currentRevisionResult.data[0]

          const result = await api.stanza_revisions.list({ stanza_id: newId, order_by: "id_desc" })

          const lastIndex = result.data.length - 1;

          if (lastIndex > 0) {
            for(let i = 0; i < lastIndex; ++i) {
              stanzaRevisions.value.push({
                revision: result.data[i],
                previousRevision: result.data[i + 1]
              })
            }
          }
          stanzaRevisions.value.push({
            revision: result.data[lastIndex]
          })
          */
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

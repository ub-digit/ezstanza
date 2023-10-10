import { defineStore } from 'pinia'
import api from '@/services/api'

export const useStanzaRevisionsStore = defineStore('stanzaRevisions', {
  state: () => ({
    /** @type {{ user: {id: number, username: string, name: string}, updated_at: string, id: number, is_current_revision: boolean }[]} */
    stanzaRevisions: [],
    currentStanzaRevision: {},
    stanzaId: null
  }),
  actions: {
    // TODO: limit?
    async fetchStanzaRevisions() {
      const currentStanzaRevisionResult = await api.stanza_revisions.list(
        {
          stanza_id: this.stanzaId,
          is_current_revision: true
        }
      )
      this.currentStanzaRevision = currentStanzaRevisionResult.data[0]

      //TODO: Try/catch?
      const result = await api.stanza_revisions.list({ stanza_id: this.stanzaId, order_by: "id_desc" })
      this.stanzaRevisions = result.data
    },
  },
})

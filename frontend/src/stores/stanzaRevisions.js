import { defineStore } from 'pinia'
import api from '@/services/api'

export const useStanzaRevisionsStore = defineStore('stanzaRevisions', {
  state: () => ({
    /** @type {{ user: {id: number, username: string, name: string}, updated_at: string, id: number, is_current_revision: boolean }[]} */
    stanzaRevisions: [],
    currentStanzaRevision: {},
    stanzaId: null
  }),
  getters: {
    stanzaRevisionsWithPrevious: (state) => {
      const result = []
      if (state.stanzaRevisions.length) {
        const lastIndex = state.stanzaRevisions.length - 1
        if (lastIndex > 0) {
          for(let i = 0; i < lastIndex; ++i) {
            result.push({
              revision: state.stanzaRevisions[i],
              previousRevision: state.stanzaRevisions[i + 1]
            })
          }
        }
        result.push({
          revision: state.stanzaRevisions[lastIndex]
        })
      }
      return result
    }
  },
  actions: {
    // TODO: limit?
    async fetchStanzaRevisions(stanzaId) {
      const currentStanzaRevisionResult = await api.stanza_revisions.list(
        {
          stanza_id: stanzaId,
          is_current_revision: true
        }
      )
      this.stanzaId = stanzaId
      this.currentStanzaRevision = currentStanzaRevisionResult.data[0]
      //TODO: Try/catch?
      const result = await api.stanza_revisions.list({ stanza_id: this.stanzaId, order_by: "id_desc" }) 
      this.stanzaRevisions = result.data
    },
  },
})

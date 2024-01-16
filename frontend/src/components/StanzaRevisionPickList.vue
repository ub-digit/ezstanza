<script>
import Button from 'primevue/button'
import { ref, toRef, inject, watch } from 'vue'

import Column from 'primevue/column'
import DataTable from 'primevue/datatable'
import MultiSelect from 'primevue/multiselect'
import UseUserColumn from '@/components/UseUserColumn.js'
import StanzaRevisionSelectDialogButton from '@/components/StanzaRevisionSelectDialogButton.vue'
import EntitySelect from '@/components/EntitySelect.vue'

export default {
  emits: ['update:modelValue'], //selection instead of modelValue?
  inheritAttrs: false,
  props: {
    modelValue: {
      type: Array,
      required: true
    },
    openLabel: {
      type: String
    },
    dialogHeader: {
      type: String
    },
    addLabel: {
      type: String,
    },
    removeLabel: {
      type: String,
    },
    params: {
      tupe: Object,
      default: {},
    }
  },
  setup(props, { emit }) {

    const dayjs = inject('dayjs')
    const pageSize = ref(5)
    const sortField = ref('updated_at')
    const sortOrder = ref(-1)

    const selectedStanzaRevisions = ref([])
    const addedStanzaRevisions = ref([])
    const selectedPickedStanzaRevisions = ref([])


    // TODO: try without toRef>
    const params = toRef(props, 'params')

    /*
    watch(addedStanzaRevisions, (newAddedStanzaRevisions) => {
      params.value['id_not_in'] = newAddedStanzaRevisions.map(
        stanzaRevision => stanzaRevision.id
      ).join(',')
      selectedStanzaRevisions.value = []
    })
    */

    const pickedStanzaRevisions = ref([])
    const onAddStanzaRevisions = (newAddedStanzaRevisions) => {
      pickedStanzaRevisions.value = pickedStanzaRevisions.value.concat(newAddedStanzaRevisions)
      /*
      params.value['id_not_in'] = pickedStanzaRevisions.value.map(
        stanzaRevision => stanzaRevision.id
      ).join(',')
      selectedStanzaRevisions.value = []
      emit('update:modelValue', pickedStanzaRevisions.value)
      */
    }
    // TODO: Use composable for stanza revisions entity select properties??

    const filters = ref({})
    //TODO: watcer for pickedStanzaRevions sync id_not_in
    const removePickedStanzaRevisions = () => {
      pickedStanzaRevisions.value = pickedStanzaRevisions.value.filter( (stanzaRevision) => {
        return !selectedPickedStanzaRevisions.value.some(
          selectedStanzaRevision => selectedStanzaRevision.id === stanzaRevision.id
        )
      })
      selectedPickedStanzaRevisions.value = []
    }

    watch(pickedStanzaRevisions, (newPickedStanzaRevisions) => {
      emit('update:modelValue', pickedStanzaRevisions.value)
    })

    // TODO: This is fucked
    watch(() => props.modelValue, (newValue) => {
      params.value['id_not_in'] = newValue.map(
        stanzaRevision => stanzaRevision.id
      ).join(',')

      if (!params.value['id_not_in']) {
        delete params.value['id_not_in']
      }
      selectedStanzaRevisions.value = []
    })

    return {
      dayjs,
      pageSize,
      sortField,
      sortOrder,
      selectedStanzaRevisions,
      addedStanzaRevisions,
      onAddStanzaRevisions,
      pickedStanzaRevisions,
      selectedPickedStanzaRevisions,
      filters,
      removePickedStanzaRevisions
    }
  },
  components: {
    EntitySelect,
    MultiSelect,
    Column,
    Button,
    StanzaRevisionSelectDialogButton
  }
}

</script>
<template>
  <StanzaRevisionSelectDialogButton
    class="mb-2"
    :label="openLabel"
    :dialogHeader="dialogHeader"
    :addLabel="addLabel"
    :modelValue="addedStanzaRevisions"
    @update:modelValue="onAddStanzaRevisions"
    v-model:selected="selectedStanzaRevisions"
    :params="params"
  />

  <template v-if="pickedStanzaRevisions.length">
    <EntitySelect
      :entities="pickedStanzaRevisions"
      v-model:selection="selectedPickedStanzaRevisions"
      :pageSize="pageSize"
      :sortField="sortField"
      :sortOrder="sortOrder"
      filterDisplay="row"
      :filters="filters"
      :selectable="true"
      :lazy="false"
    >
      <Column
        header="Name"
        field="name"
        sortable
      />
      <template #reserved>
        <Column field="updated_at" header="Updated" :sortable="true">
          <template #body="{ data }">
            {{ dayjs(data.updated_at).format('L LT') }}
          </template>
        </Column>
        <Column
          header="Updated by"
          field="user.name"
        />
      </template>
    </EntitySelect>
    <Button class="mt-3 mb-2" severity="secondary" @click="removePickedStanzaRevisions" :label="removeLabel"/>
  </template>
</template>

<style>
</style>

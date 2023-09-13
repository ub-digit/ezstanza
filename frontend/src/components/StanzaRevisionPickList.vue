<script>
import Button from 'primevue/button'
import { ref, toRef, inject, watch } from 'vue'

import Column from 'primevue/column'
import DataTable from 'primevue/datatable'
import MultiSelect from 'primevue/multiselect'
import UseEntityDataTable from '@/components/UseEntityDataTable.js'
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
    addLabel: {
      type: String
    },
    params: {
      tupe: Object,
      default: {},
    }
  },
  setup(props, { emit }) {

    const dayjs = inject('dayjs')
    const loading = ref(false)
    const pageSize = ref(5)
    const defaultSortField = ref('updated_at')
    const defaultSortOrder = ref(-1)

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
      params.value['id_not_in'] = pickedStanzaRevisions.value.map(
        stanzaRevision => stanzaRevision.id
      ).join(',')

      if (!params.value['id_not_in']) {
        delete params.value['id_not_in']
      }
      selectedStanzaRevisions.value = []
      emit('update:modelValue', pickedStanzaRevisions.value)
    })

    return {
      dayjs,
      loading,
      pageSize,
      defaultSortField,
      defaultSortOrder,
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
  <StanzaRevisionSelectDialogButton class="mb-2" :label="addLabel" :modelValue="addedStanzaRevisions"  @update:modelValue="onAddStanzaRevisions" v-model:selected="selectedStanzaRevisions" :params="params"/>

  <template v-if="pickedStanzaRevisions.length">
    <EntitySelect
      :entities="pickedStanzaRevisions"
      v-model:selectedEntities="selectedPickedStanzaRevisions"
      :pageSize="pageSize"
      :loading="loading"
      :defaultSortField="defaultSortField"
      :defaultSortOrder="defaultSortOrder"
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
    <Button class="mt-3 mb-2" severity="secondary" @click="removePickedStanzaRevisions" label="Remove"/>
  </template>
</template>

<style>
</style>

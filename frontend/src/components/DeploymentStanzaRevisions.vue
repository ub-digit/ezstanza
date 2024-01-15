<script>
import { ref, inject } from 'vue'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import InputText from 'primevue/inputtext'
import Dropdown from 'primevue/dropdown'
import useEntityDataTable from '@/components/UseEntityDataTable.js'
import { FilterMatchMode } from 'primevue/api'

export default {
  props: {
    deployment: {
      type: Object,
      required: true
    }
  },
  setup({ deployment }) {
    const api = inject('api')
    const dayjs = inject('dayjs')
    const params = ref({
      deployment_id: deployment.id
    })

    const isCurrentRevisionOptions = ref([
      {
        label: 'Yes',
        value: true
      }, {
        label: 'No',
        value: false
      }
    ])

    const {
      entities: stanzaRevisions,
      dataTableEvents: dataTableEvents,
      dataTableProperties: dataTableProperties,
      lazyParams: lazyParams,
      pageSize: pageSize
    } = useEntityDataTable({
      lazy: true,
      params: params,
      entityNamePluralized: 'stanza_revisions',
      entityLabelPluralized: 'Stanza revisions',
      defaultPageSize: 10,
      defaultSortField: 'inserted_at',
      defaultSortOrder: -1
    })

    //todo; params into useEntitydatatalbe

    const filters = ref({
      name: {value: null, matchMode: FilterMatchMode.CONTAINS},
      is_current_revision: {value: null, matchMode: FilterMatchMode.EQUALS}
    })
    const expandedRows = ref([])

    return {
      stanzaRevisions,
      pageSize,
      dataTableEvents,
      dataTableProperties,
      filters,
      expandedRows,
      isCurrentRevisionOptions,
      dayjs
    }
  },
  components: {
    DataTable,
    Column,
    InputText,
    Dropdown
  }
}
</script>
<template>
  <DataTable
    :value="stanzaRevisions"
    ref="dt"
    dataKey="id"
    v-on="dataTableEvents"
    v-bind="dataTableProperties"
    v-model:rows="pageSize"
    v-model:filters="filters"
    v-model:expandedRows="expandedRows"
    filterDisplay="row"
    resonsiveLayout="scroll"
    :rowsPerPageOptions="[10,25,50,100]"
  >

    <Column expander/>
    <Column
      field="name"
      filterField="name"
      :showFilterMenu="false"
      header="Name"
      sortable
    >
      <template #filter="{ filterModel, filterCallback }">
        <InputText type="text" v-model="filterModel.value" @keydown.enter="filterCallback()" placeholder="Search"/>
      </template>
    </Column>
    <Column field="id" header="Revision id">
    </Column>
    <Column
      field="is_current_revision"
      filterField="is_current_revision"
      :showFilterMenu="false"
      header="Current revision"
    >
      <template #filter="{ filterModel, filterCallback }">
        <Dropdown
          :options="isCurrentRevisionOptions"
          optionLabel="label"
          optionValue="value"
          v-model="filterModel.value"
          @change="filterCallback()"
          placeholder="Any"
        />
      </template>
      <template #body="{ data : { is_current_revision : is_current } }">
        <template v-if="is_current">
          Yes
        </template>
        <template v-else>
          No
        </template>
      </template>
    </Column>
    <Column field="updated_at" header="Updated" :sortable="true">
      <template #body="{ data }">
        {{ dayjs(data.inserted_at).format('L LT') }}
      </template>
    </Column>

    <template #expansion="{ data }">
      <div class="grid">
        <pre class="col-12">{{ data.body }}</pre>
      </div>
    </template>
  </DataTable>
</template>

<script>
import { inject, ref, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import StanzaList from '@/components/StanzaList.vue'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import ColumnGroup from 'primevue/columngroup'
import Row from 'primevue/row'
import { FilterMatchMode } from 'primevue/api'

export default {
  setup() {

    const route = useRoute()
    const api = inject('api')

    const loading = ref(false)
    const lazyParams = ref({})
    const dt = ref()
    const selectAll  = ref(false)
    const selectedStanzas = ref()
    const stanzas = ref([])
    const pageSize = ref(50)
    const totalStanzas = ref(0)
    const expandedRows = ref([])

    const filters = ref({
      'name': {value: '', matchMode: FilterMatchMode.CONTAINS},
      'user_name': {value: '', matchMode: FilterMatchMode.CONTAINS},
    })
    const filterMatchModeOptions = [
      { label: 'Contains', value: FilterMatchMode.CONTAINS },
      { label: 'Equals', value: FilterMatchMode.EQUALS },
    ]

    const filterSuffix = {
      [FilterMatchMode.CONTAINS]: '_like',
      [FilterMatchMode.EQUALS]: ''
    }

    const sortSuffix = []
    sortSuffix[1] = ''
    sortSuffix[-1] = '_desc'

    const onPage = (event) => {
      lazyParams.value = event
      console.log('on page')
    }
    //TODO: Default sort?
    const onSort = (event) => {
      lazyParams.value['order_by'] = event.sortField + (event.sortOrder === 1 ? '_desc' : '')
    }
    const onFilter = () => {
      let filterParams = {}
      for (const [filter, data] of Object.entries(filters.value)) {
        const filter_name = filter + filterSuffix[data.matchMode]
        if (data.value.length) {
          lazyParams.value[filter_name] = data.value
        }
        else {
          delete lazyParams.value[filter_name]
        }
      }
    }

    onMounted(() => {
      loading.value = true
      lazyParams.value = {
        page: 1,
        size: dt.value.rows,
        sortField: null,
        sortOrder: null,
      }
    })

    const lazyLoadData = () => {
      loading.value = true
      api.stanzas.list(lazyParams.value).then(result => {
        stanzas.value = result.data
        totalStanzas.value = result.total
        loading.value = false
      })
    }

    const onSelectAllChange = (event) => {
      if (event.checked) {
        // If not all stanzas fit into the first page
        // load all from backend
        if (stanzas.value.length < totalStanzas.value) {
          let params = Object.assign({}, lazyParams.value)
          delete params.page
          delete params.size
          api.stanzas.list(params).then(result => {
            selectAll.value = true
            selectedStanzas.value = result.data
          })
        }
        else {
          selectAll.value = true
          selectedStanzas.value = stanzas.value
        }
      }
      else {
        selectAll.value = false;
        selectedStanzas.value = [];
      }
    }
    const onRowSelect = () => {
      selectAll.value = selectedStanzas.value.length === totalStanzas.value;
    }
    const onRowUnselect = () => {
      selectAll.value = false;
    }

    watch(
      () => lazyParams,
      async newParams => {
        loading.value = true
        api.stanzas.list(newParams.value).then(result => {
          stanzas.value = result.data
          totalStanzas.value = result.total
          loading.value = false
        })
      },
      { immediate: true, deep: true }
    )
    /*

    watch(
      () => route.query.page,
      async newPage => {
        newPage = newPage || 1
        const result = await api.stanzas.list({ page: newPage, size: pageSize.value })
        stanzas.value = result.data
        totalStanzas.value = result.total
      },
      { immediate: true }
    )
    */

    return {
      stanzas,
      totalStanzas,
      pageSize,
      expandedRows,
      loading,
      selectedStanzas,
      filters,
      onFilter,
      onSort,
      onPage,
      onSelectAllChange,
      onRowSelect,
      onRowUnselect,
      selectAll,
      filterMatchModeOptions,
      dt
    }
  },
  components: {
    StanzaList,
    DataTable,
    Column
  }
}
</script>
<template>
  <DataTable
    :value="stanzas"
    :lazy="true"
    :paginator="true"
    :rows="pageSize"
    ref="dt"
    dataKey="id"
    @page="onPage($event)"
    @sort="onSort($event)"
    @filter="onFilter($event)"
    filterDisplay="row"
    v-model:filters="filters"
    v-model:selection="selectedStanzas"
    v-model:expandedRows="expandedRows"
    :selectAll="selectAll"
    @select-all-change="onSelectAllChange"
    @row-select="onRowSelect"
    @row-unselect="onRowUnselect"
    resonsiveLayout="scroll"
    :totalRecords="totalStanzas"
    :loading="loading"
  >
    <Column selectionMode="multiple" headerStyle="width: 3em"/>
    <Column :expander="true" headerStyle="width: 3em"/>
    <Column field="name" header="Name" filterMatchMode="startsWith" ref="name" :filterMatchModeOptions="filterMatchModeOptions" :sortable="true">
      <template #filter="{filterModel,filterCallback}">
        <InputText type="text" v-model="filterModel.value" @keydown.enter="filterCallback()" placeholder="Search"/>
      </template>
    </Column>
    <Column field="user.name" header="Created by" filterMatchMode="startsWith" ref="user.name" :filterMatchModeOptions="filterMatchModeOptions" filterField="user_name" :sortable="true">
      <template #filter="{filterModel,filterCallback}">
        <InputText type="text" v-model="filterModel.value" @keydown.enter="filterCallback()" placeholder="Search"/>
      </template>
    </Column>
    <Column field="inserted_at" header="Created" :sortable="true"/>
    <Column field="updated_at" header="Updated" :sortable="true"/>
    <template #expansion="{ data }">
      <div class="grid">
        <div class="col-12">{{ data.body }}</div>
      </div>
    </template>
  </DataTable>

</template>

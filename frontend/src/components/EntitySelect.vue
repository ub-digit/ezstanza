<script>
import { toRef, ref, unref, watch } from 'vue'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import { FilterMatchMode } from 'primevue/api'

export default {
  props: {
    defaultSortField: {
      type: String,
      required: true
    },
    defaultSortOrder: {
      type: Number,
      required: true
    },
    filterColumns: {
      type: Array
    },
    entities: {
      type: Array
    },
    totalEntities: {
      type: Number
    },
    selectedEntities: {
      type: Array
    },
    pageSize: {
      type: Number
    },
    loading: {
      type: Boolean
    },
    loadEntitiesUnpaginated: {
      type: Function
    }
  },
  emits: ['update:selectedEntities', 'update:entities', 'sort', 'page', 'filter'],
  setup(props, context) {

    const defaultSortField = toRef(props, 'defaultSortField')
    const defaultSortOrder = toRef(props, 'defaultSortOrder')

    const dt = ref() //TODO: remove??
    const selectAll  = ref(false)
    //const selectedEntities = toRef(props, 'selectedEntities')
    const selectedEntities = ref(unref(props.selectedEntities)) //??
    const entities = toRef(props, 'entities')
    const pageSize = toRef(props, 'pageSize')
    const totalEntities = toRef(props, 'totalEntities')
    const expandedRows = ref([])

    const expandableRows = context.slots.expansion !== undefined

    // Hack of the century
    let filtersChanged = false

    // Watch entities and possibly remove
    // from selection on filtering
    watch(entities, (newValue) => {
      if (filtersChanged) {
        let ids = []
        for (const entity of newValue) {
          ids[entity.id] = true
        }
        selectedEntities.value = selectedEntities.value.filter(
          (entity) => ids[entity.id]
        )
        onRowSelect()
        filtersChanged = false
      }
    })

    watch(selectedEntities, (newValue) => {
      context.emit('update:selectedEntities', newValue)
    })

    // How to handle if empty?
    const filters = ref(Object.fromEntries(
      props.filterColumns.map(
        filterColumn => [
          filterColumn.filterFieldName,
          { value: '', matchMode: FilterMatchMode.CONTAINS }
        ]
      )
    ))

    const filterMatchModeOptions = [
      { label: 'Contains', value: FilterMatchMode.CONTAINS },
      { label: 'Equals', value: FilterMatchMode.EQUALS },
    ]

    const filterSuffix = {
      [FilterMatchMode.CONTAINS]: '_like',
      [FilterMatchMode.EQUALS]: ''
    }

    const onPage = (event) => {
      context.emit('page', event)
    }

    //TODO: Default sort by new
    const onSort = (event) => {
      context.emit('sort', event)
    }

    const onFilter = (event) => {
      let newFilters = {}
      for (const [filter, data] of Object.entries(event.filters)) {
        const filter_name = filter + filterSuffix[data.matchMode]
        newFilters[filter_name] = data.value
      }
      filtersChanged = true
      context.emit('filter', newFilters)
    }

    const onSelectAllChange = (event) => {
      if (event.checked) {
        // If not all entities fit into the first page
        // load all from backend
        if (entities.value.length < totalEntities.value) {
          props.loadEntitiesUnpaginated().then(entities => {
            selectAll.value = true
            selectedEntities.value = entities
          })
        }
        else {
          selectAll.value = true
          selectedEntities.value = entities.value
        }
      }
      else {
        selectAll.value = false
        selectedEntities.value = []
        context.emit('update:selectedEntities', [])
      }
    }
    const onRowSelect = () => {
      selectAll.value = selectedEntities.value.length === totalEntities.value
    }
    const onRowUnselect = () => {
      selectAll.value = false
    }

    return {
      entities,
      totalEntities,
      pageSize,
      expandedRows,
      selectedEntities,
      filters,
      defaultSortField,
      defaultSortOrder,
      onFilter,
      onSort,
      onPage,
      onSelectAllChange,
      onRowSelect,
      onRowUnselect,
      selectAll,
      filterMatchModeOptions,
      dt,
      expandableRows
    }
  },
  components: {
    DataTable,
    Column
  }
}
</script>
<template>
  <DataTable
    :value="entities"
    :lazy="true"
    :paginator="!loading"
    :rows="pageSize"
    ref="dt"
    dataKey="id"
    :sortField="defaultSortField"
    :sortOrder="defaultSortOrder"
    @page="onPage($event)"
    @sort="onSort($event)"
    @filter="onFilter($event)"
    filterDisplay="row"
    v-model:filters="filters"
    v-model:selection="selectedEntities"
    v-model:expandedRows="expandedRows"
    :selectAll="selectAll"
    @select-all-change="onSelectAllChange"
    @row-select="onRowSelect"
    @row-unselect="onRowUnselect"
    resonsiveLayout="scroll"
    :totalRecords="totalEntities"
    paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
    :rowsPerPageOptions="[10,25,50]"
    currentPageReportTemplate="Showing {first} to {last} of {totalRecords} entities"
    :loading="loading"
  >
    <Column selectionMode="multiple" headerStyle="width: 3em"/>
    <Column v-if="expandableRows" :expander="true" headerStyle="width: 3em"/>
    <template v-for="column in filterColumns">
      <Column
        :field="column.fieldName"
        :filterField="column.filterFieldName"
        :header="column.header"
        filterMatchMode="startsWith"
        :ref="column.fieldName"
        :filterMatchModeOptions="filterMatchModeOptions"
        :sortable="true"
      >
        <template #filter="{ filterModel, filterCallback }">
          <InputText type="text" v-model="filterModel.value" @keydown.enter="filterCallback()" placeholder="Search"/>
        </template>
      </Column>
    </template>
    <slot></slot>
    <template v-if="expandableRows" #expansion="{ data }">
      <slot name="expansion" :data="data"></slot>
    </template>
  </DataTable>
</template>

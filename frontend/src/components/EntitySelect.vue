<script>
import { toRef, toRaw, ref, unref, watch, computed } from 'vue'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import InputText from 'primevue/inputtext'
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
    filters: {
      type: Object
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
    },
    selectable: {
      type: Boolean,
      default: true
    },
    filterDisplay: {
      type: String,
      default: "row"
    },
    lazy: {
      type: Boolean,
      default: true
    }
  },
  emits: ['update:selectedEntities', 'sort', 'page', 'filter'],
  setup(props, context) {

    const defaultSortField = toRef(props, 'defaultSortField')
    const defaultSortOrder = toRef(props, 'defaultSortOrder')

    const dt = ref() //TODO: remove??
    const selectAll  = ref(false)

    const entities = toRef(props, 'entities')
    const pageSize = toRef(props, 'pageSize')
    const totalEntities = toRef(props, 'totalEntities')
    const expandedRows = ref([])

    const expandableRows = context.slots.expansion !== undefined

    // Hack of the century
    let filtersChanged = false

    // TODO: filtering when all selected?
    // Watch entities and possibly remove
    // from selection on filtering
    // TODO: paginering ballar ur
    watch(entities, (newValue) => {
      if (filtersChanged) {
        let ids = []
        for (const entity of newValue) {
          ids[entity.id] = true
        }

        onUpdateSelection(
          props.selectedEntities.filter(
            entity => ids[entity.id]
          ).map(entity => toRaw(entity))
        )
        filtersChanged = false
      }
    })
    const totalEntitiesLength = computed(() => {
      return props.totalEntities ? props.totalEntities : props.entities.length
    })

    watch(() => props.selectedEntities, () => {
      // TODO: Since total entities set depending on lazy in parent component
      // perhaps don't need to use computed property in dt
      // or duplicate computed property here
      //selectAll.value = props.selectedEntities.length === dt.value.totalRecordsLength
      selectAll.value = props.selectedEntities.length === totalEntitiesLength.value
    })

    const onUpdateSelection = (value) => {
      if (props.selectable) {
        context.emit('update:selectedEntities', value)
      }
    }

    const filters = ref(toRaw(props.filters) || {})
    if (props.filterColumns) {
      Object.assign(
        filters.value,
        Object.fromEntries(
          props.filterColumns.map(
            filterColumn => [
              filterColumn.filterFieldName,
              { value: '', matchMode: filterColumn.defaultFilterMatchMode || FilterMatchMode.CONTAINS }
            ]
          )
        )
      )
    }

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
        if (entities.value.length < totalEntitiesLength.value) {
          props.loadEntitiesUnpaginated().then(entities => {
            selectAll.value = true
            onUpdateSelection(entities)
          })
        }
        else {
          selectAll.value = true
          onUpdateSelection(entities.value)
        }
      }
      else {
        selectAll.value = false
        onUpdateSelection([])
      }
    }

    // Hide paginator if all entities are currently displayed
    const showPaginator = computed(() => {
      return entities.length <= totalEntitiesLength.value
    })

    return {
      entities,
      totalEntities,
      pageSize,
      expandedRows,
      filters,
      defaultSortField,
      defaultSortOrder,
      onFilter,
      onSort,
      onPage,
      onSelectAllChange,
      onUpdateSelection,
      selectAll,
      filterMatchModeOptions,
      dt,
      expandableRows,
      showPaginator
    }
  },
  components: {
    InputText,
    DataTable,
    Column
  }
}
</script>
<template>
  <DataTable
    :value="entities"
    :lazy="lazy"
    :paginator="showPaginator"
    :rows="pageSize"
    ref="dt"
    dataKey="id"
    :sortField="defaultSortField"
    :sortOrder="defaultSortOrder"
    @page="onPage($event)"
    @sort="onSort($event)"
    @filter="onFilter($event)"
    :filterDisplay="filterDisplay"
    v-model:filters="filters"
    :selection="selectedEntities"
    @update:selection="onUpdateSelection"
    compareSelectionBy="id"
    v-model:expandedRows="expandedRows"
    :selectAll="selectAll"
    @select-all-change="onSelectAllChange"
    resonsiveLayout="scroll"
    :totalRecords="totalEntities"
    paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
    :rowsPerPageOptions="[10,25,50]"
    currentPageReportTemplate="Showing {first} to {last} of {totalRecords} entities"
    :loading="loading"
  >
    <Column v-if="selectable" selectionMode="multiple" headerStyle="width: 3em"/>
    <Column v-if="expandableRows" :expander="true" headerStyle="width: 3em"/>
    <template v-for="column in filterColumns">
      <Column
        :field="column.fieldName"
        :filterField="column.filterFieldName"
        :header="column.header"
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
    <slot name="reserved"></slot>
    <template v-if="expandableRows" #expansion="{ data }">
      <slot name="expansion" :data="data"></slot>
    </template>
  </DataTable>
</template>

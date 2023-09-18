<script>
import { toRef, toRaw, ref, unref, watch, computed } from 'vue'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import InputText from 'primevue/inputtext'
import Chip from 'primevue/chip'
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
      type: Array,
      default: []
    },
    filters: {
      type: Object,
      default: {}
    },
    entities: {
      type: Array
      // default??
    },
    totalEntities: {
      type: Number
    },
    selectedEntities: {
      type: Array,
      default: [], //???
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
    const totalEntities = toRef(props, 'totalEntities')
    const expandedRows = ref([])

    const expandableRows = context.slots.expansion !== undefined

    /*
    // Hack of the century
    let filtersChanged = false

    // TODO: filtering when all selected?
    // Watch entities and possibly remove
    // from selection on filtering
    // TODO: paginering ballar ur
    watch(entities, (newEntities) => {
      if (filtersChanged) {
        let ids = []
        for (const entity of newEntities) {
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
    */
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

    const onUpdateSelection = (newSelectedEntities) => {
      if (props.selectable) {
        //@FIXME map toRaw, to get rid of proxy objects, wtf why does datatable do this??
        context.emit(
          'update:selectedEntities',
          newSelectedEntities.map(entity => toRaw(entity))
        )
      }
    }

    // Hack, toRef(props, 'filters') is readonly
    // not sure why works in EntityList though
    // perhaps assigning properties is allowed,
    // but really should get a better grip of this
    const filters = ref({})
    watch(() => props.filters, (newFilters, oldFilters) => {
      if (oldFilters) {
        newFilters.keys().forEach(key => {
          if (!key in oldFilters) {
            delete filters.value[key]
          }
        })
      }
      Object.assign(
        filters.value,
        newFilters
      )
    }, {immediate: true })

    watch(() => props.filterColumns, (newFilterColumns, oldFilterColumns) => {
      if (oldFilterColumns) {
        // Delete possibly removed filter columns
        // FIXME: Currently untested
        const oldFilterFieldNames = oldFilterColums.map(filterColumn => filterColumn.filterFieldName)
        newfilterColumns.forEach(filterColumn => {
          if (!oldFilterFieldNames.includes(filterColumn.filterFieldName)) {
            delete filters.value[filterColumn.filterFieldName]
          }
        })
      }
      //Add new filter columns
      Object.assign(
        filters.value,
        Object.fromEntries(
          newFilterColumns.map(
            filterColumn => [
              filterColumn.filterFieldName,
              {
                value: '',
                matchMode: filterColumn.defaultFilterMatchMode || FilterMatchMode.EQUALS
              }
            ]
          )
        )
      )
    }, {immediate: true })

    const filterMatchModeOptions = [
      { label: 'Contains', value: FilterMatchMode.CONTAINS },
      { label: 'Equals', value: FilterMatchMode.EQUALS },
    ]

    const onPage = (event) => {
      context.emit('page', event)
    }

    //TODO: Default sort by new
    const onSort = (event) => {
      context.emit('sort', event)
    }

    const onFilter = (event) => {
      //filtersChanged = true
      context.emit('filter', event)
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
          onUpdateSelection(toRaw(entities.value))
        }
      }
      else {
        selectAll.value = false
        onUpdateSelection([])
      }
    }

    // Hide paginator if all entities are currently displayed
    const showPaginator = computed(() => {
      // Feature not a but that page size not reacative
      // since don't want to hide pagination if first
      // visiable even if increasing page size to fit all
      // entities
      return totalEntitiesLength.value > props.pageSize
    })

    const selectedHeaderText = computed(() => {
      return `${props.selectedEntities.length}`
    })

    return {
      entities,
      totalEntitiesLength,
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
      showPaginator,
      selectedHeaderText
    }
  },
  components: {
    InputText,
    DataTable,
    Column,
    Chip
  }
}
</script>
<template>
  <!-- TODO: rowsPerPageOptions need adjusting for initial pageSize, computed? -->
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
    v-model:expandedRows="expandedRows"
    :selectAll="selectAll"
    @select-all-change="onSelectAllChange"
    resonsiveLayout="scroll"
    :totalRecords="totalEntitiesLength"
    paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
    :rowsPerPageOptions="[10,25,50]"
    currentPageReportTemplate="Showing {first} to {last} of {totalRecords} entities"
    :loading="loading"
  >
    <Column v-if="selectable" selectionMode="multiple" style="width: 3em">
      <template v-if="selectedEntities.length" #header>
        <Chip class="bg-primary" icon="pi pi-file" :label="selectedHeaderText"/>
      </template>
    </Column>
    <Column v-if="expandableRows" :expander="true"/>
    <template v-for="column in filterColumns">
      <Column
        :field="column.fieldName"
        :filterField="column.filterFieldName"
        :sortField="column.filterFieldName"
        :header="column.header"
        :ref="column.fieldName"
        :showFilterMenu="column.showFilterMenu"
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

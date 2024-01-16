<script>
import { toRef, toRaw, ref, unref, watch, computed } from 'vue'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import InputText from 'primevue/inputtext'
import Chip from 'primevue/chip'
import { FilterMatchMode } from 'primevue/api'

//TODO: When getting props from UseEntityDataTable, issues with v-bind etc
// Duplication of showPaginator and other stuff
export default {
  props: {
    sortField: {
      type: String,
      required: true
    },
    sortOrder: {
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
    totalRecords: {
      type: Number
    },
    selection: {
      type: Array,
      default: [], //???
    },
    pageSize: {
      type: Number,
      default: 10
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
  emits: ['update:selection', 'sort', 'page', 'filter'],
  setup(props, context) {

    const sortField = toRef(props, 'sortField')
    const sortOrder = toRef(props, 'sortOrder')

    const dt = ref() //TODO: remove??
    const selectAll  = ref(false)

    const entities = toRef(props, 'entities')
    const totalRecords = toRef(props, 'totalRecords')
    const expandedRows = ref([])

    const expandableRows = context.slots.expansion !== undefined

    const totalRecordsLength = computed(() => {
      return props.totalRecords ? props.totalRecords : props.entities.length
    })

    watch(() => props.selection, () => {
      // TODO: Since total entities set depending on lazy in parent component
      // perhaps don't need to use computed property in dt
      // or duplicate computed property here
      //selectAll.value = props.selection.length === dt.value.totalRecordsLength
      selectAll.value = props.selection.length === totalRecordsLength.value
    })

    const onUpdateSelection = (newSelectedEntities) => {
      if (props.selectable) {
        //@FIXME map toRaw, to get rid of proxy objects, wtf why does datatable do this??
        context.emit(
          'update:selection',
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
                value: null,
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
        if (entities.value.length < totalRecordsLength.value) {
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
      return totalRecordsLength.value > props.pageSize
    })

    const selectedHeaderText = computed(() => {
      return `${props.selection.length}`
    })

    return {
      entities,
      totalRecordsLength,
      expandedRows,
      filters,
      sortField,
      sortOrder,
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
    :sortField="sortField"
    :sortOrder="sortOrder"
    @page="onPage($event)"
    @sort="onSort($event)"
    @filter="onFilter($event)"
    :filterDisplay="filterDisplay"
    v-model:filters="filters"
    :selection="selection"
    @update:selection="onUpdateSelection"
    v-model:expandedRows="expandedRows"
    :selectAll="selectAll"
    @select-all-change="onSelectAllChange"
    resonsiveLayout="scroll"
    :totalRecords="totalRecordsLength"
    paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
    :rowsPerPageOptions="[10,25,50]"
    currentPageReportTemplate="Showing {first} to {last} of {totalRecords} entities"
    :loading="loading"
    :rowClass="(data) => data.disabled ? 'text-500' : null"
  >
    <Column v-if="selectable" selectionMode="multiple" style="width: 3em">
      <template v-if="selection.length" #header>
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
        <template #body="{ field, data }">
          {{ data[field] }}
          <span v-if="data.disabled && field === 'name'">
            (Disabled)
          </span>
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

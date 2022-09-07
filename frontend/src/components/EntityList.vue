<script>
import { inject, toRef, ref, unref, toRaw, watch, onMounted } from 'vue'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import { FilterMatchMode } from 'primevue/api'
import Button from 'primevue/button'
import Toolbar from 'primevue/toolbar'
import ConfirmDialogButton from '@/components/ConfirmDialogButton.vue'

export default {
  props: {
    createRouteName: {
      type: String,
      required: true
    },
    editRouteName: {
      type: String,
      required: true
    },
    destinationPath: {
      type: String,
      required: true
    },
    entityName: {
      type: String,
      required: true
    },
    entityNamePluralized: {
      type: String,
      required: true
    },
    defaultSortField: {
      type: String,
      required: true
    },
    filterColumns: {
      type: Array
    }
  },
  setup(props, context) {

    const api = inject('api')

    const defaultSortField = toRef(props, 'defaultSortField')
    const defaultSortOrder = ref(-1)

    const loading = ref(false)
    const lazyParams = ref({})
    const dt = ref()
    const selectAll  = ref(false)
    const selectedEntities = ref([])
    const entities = ref([])
    const pageSize = ref(10)
    const totalEntities = ref(0)
    const expandedRows = ref([])

    const expandableRows = context.slots.expansion !== undefined

    // How to handle if empty? //ref or not?

    const filters = Object.fromEntries(
      props.filterColumns.map(
        filterColumn => [
          filterColumn.filterFieldName,
          { value: '', matchMode: FilterMatchMode.CONTAINS }
        ]
      )
    )
    /*
    const filters = ref({
      'name': {value: '', matchMode: FilterMatchMode.CONTAINS},
      'user_name': {value: '', matchMode: FilterMatchMode.CONTAINS},
    })
    */

    const filterMatchModeOptions = [
      { label: 'Contains', value: FilterMatchMode.CONTAINS },
      { label: 'Equals', value: FilterMatchMode.EQUALS },
    ]

    const filterSuffix = {
      [FilterMatchMode.CONTAINS]: '_like',
      [FilterMatchMode.EQUALS]: ''
    }

    // @todo: ugly, how to use defined standard breakpoints?
    const dialogBreakpoints = ref({
      '960px': '75vw',
      '640px': '90vw'
    })

    // Event handler with closure on entity
    const onDeleteEntity = (entity, close) => {
      // TODO: Delete from selected entities
      api[props.entityNamePluralized].delete(entity.id).then(() => {
        entities.value = entities.value.filter((s) => s.id !== entity.id)
        selectedEntities.value = selectedEntities.value.filter((s) => s.id !== entity.id)
        totalEntities.value = totalEntities.value - 1
        if (
            (lazyParams.value.size * (lazyParams.value.page - 1) + entities.value.length) < totalEntities.value &&
            entities.value.length < lazyParams.value.size
        ) {
          loadEntities(toRaw(lazyParams.value))
        }
      }).catch((error) => {
        //TODO: toast with error
      })
      close()
    }

    // @todo: add backend patch operation for bulk deletion?
    const onDeleteSelectedEntities = (close) => {
      const entityIds = selectedEntities.value.map((s) => s.id)
      Promise.all(entityIds.map((id) => api[props.entityNamePluralized].delete(id))).then(() => {
        entities.value = entities.value.filter((s) => !entityIds.includes(s.id))
        selectedEntities.value = selectedEntities.value.filter((s) => !entityIds.includes(s.id))
        totalEntities.value = totalEntities.value - entityIds.length
        loadEntities(toRaw(lazyParams.value))
        close()
      }).catch((error) => {
        // @todo: toast with error
      })
    }

    const getOrderBy = (sortField, sortOrder) => {
      return sortField + (sortOrder === -1 ? '_desc' : '')
    }

    const onPage = (event) => {
      lazyParams.value.size = event.rows
      lazyParams.value.page = event.page + 1
    }

    //TODO: Default sort by new
    const onSort = (event) => {
      lazyParams.value['order_by'] = getOrderBy(event.sortField, event.sortOrder)
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
        order_by: getOrderBy(defaultSortField.value, defaultSortOrder.value)
      }
    })

    const loadEntities = async (params) => {
      loading.value = true
      params = Object.assign({}, params)
      // Load ahead some entities so don't have to refetch
      // on every deletion
      // @todo: better name. ahead, ahead_size?
      params.extra = 5
      await api[props.entityNamePluralized].list(params).then(result => {
        entities.value = result.data
        totalEntities.value = result.total
        loading.value = false
      })
    }

    const onSelectAllChange = (event) => {
      if (event.checked) {
        // If not all entities fit into the first page
        // load all from backend
        if (entities.value.length < totalEntities.value) {
          // @todo: alternatively { ...lazyParams.value } ?
          let params = Object.assign({}, lazyParams.value)
          delete params.page
          delete params.size
          api[props.entityNamePluralized].list(params).then(result => {
            selectAll.value = true
            selectedEntities.value = result.data
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
      }
    }
    const onRowSelect = () => {
      selectAll.value = selectedEntities.value.length === totalEntities.value
    }
    const onRowUnselect = () => {
      selectAll.value = false
    }

    watch(
      () => lazyParams,
      async newParams => {
        await loadEntities(toRaw(newParams.value))
      },
      //{ immediate: true, deep: true }
      { deep: true }
    )

    /*
    watch(
      () => route.query.page,
      async newPage => {
        newPage = newPage || 1
        const result = await api[props.entityNamePluralized].list({ page: newPage, size: pageSize.value })
        entities.value = result.data
        totalEntities.value = result.total
      },
      { immediate: true }
    )
     */

    return {
      entities,
      totalEntities,
      pageSize,
      expandedRows,
      loading,
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
      onDeleteEntity,
      onDeleteSelectedEntities,
      dialogBreakpoints,
      dt,
      expandableRows
    }
  },
  components: {
    DataTable,
    Column,
    Button,
    Toolbar,
    ConfirmDialogButton
  }
}
</script>
<template>
  <Toolbar class="mb-4">
    <template #start>
      <router-link
        custom
        :to="{ name: createRouteName, query: { destination: destinationPath } }"
        v-slot="{ navigate }"
      >
        <Button label="New" icon="pi pi-plus" class="p-button-success mr-2" @click="navigate"/>
      </router-link>
      <ConfirmDialogButton
        label="Delete"
        icon="pi pi-trash"
        class="p-button-danger"
        :breakpoints="dialogBreakpoints"
        @accept="onDeleteSelectedEntities"
        :disabled="!selectedEntities || !selectedEntities.length"
      >
        <i class="pi pi-exclamation-triangle mr-3 p-confirm-dialog-icon" />
        <template #header>
          Confirm delete selection
        </template>
        <span class="p-confirm-dialog-message">Are you sure you want to delete selected {{ entityNamePluralized }}?</span>
      </ConfirmDialogButton>

    </template>
  </Toolbar>

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
    paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown" :rowsPerPageOptions="[10,25,50]"
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
    <Column field="inserted_at" header="Created" :sortable="true"/>
    <Column field="updated_at" header="Updated" :sortable="true"/>
    <Column style="min-with: 8rem">
      <template #body="{ data }">
        <div class="flex">
          <router-link
            custom
            :to="{ name: editRouteName, params: { id: data.id }, query: { destination: destinationPath} }"
            v-slot="{ navigate }"
          >
            <Button icon="pi pi-pencil" class="p-button-text p-button-info" @click="navigate"/>
          </router-link>
          <ConfirmDialogButton
            icon="pi pi-trash"
            class="p-button-text p-button-warning"
            :breakpoints="dialogBreakpoints"
            @accept="onDeleteEntity(data, $event)"
          >
            <i class="pi pi-exclamation-triangle mr-3 p-confirm-dialog-icon" />
            <template #header>
              Confirm delete
            </template>
            <span class="p-confirm-dialog-message">Are you sure you want to delete {{ entityName }}<b>"{{data.name}}"</b>?</span>
          </ConfirmDialogButton>
        </div>
      </template>
    </Column>
    <template v-if="expandableRows" #expansion="{ data }">
      <slot name="expansion" :data="data"></slot>
    </template>
  </DataTable>
</template>

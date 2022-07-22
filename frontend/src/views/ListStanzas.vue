<script>
import { inject, ref, unref, toRaw, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import StanzaList from '@/components/StanzaList.vue'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import ColumnGroup from 'primevue/columngroup'
import Row from 'primevue/row'
import { FilterMatchMode } from 'primevue/api'
import Button from 'primevue/button'
import Toolbar from 'primevue/toolbar'
import { useDialog } from 'primevue/usedialog'
//import ConfirmDelete from '@/components/ConfirmDelete.vue'
import ConfirmDialogButton from '@/components/ConfirmDialogButton.vue'

export default {
  setup() {

    // @todo: format date

    const route = useRoute()
    const dialog = useDialog()
    const api = inject('api')

    // @todo: ugly, how to use defined standard breakpoints?
    const dialogBreakpoints = ref({
      '960px': '75vw',
      '640px': '90vw'
    })

    // Event handler with closure on stanza
    const onDeleteStanza = (stanza, close) => {
      // TODO: Delete from selected stanzas
      api.stanzas.delete(stanza.id).then(() => {
        stanzas.value = stanzas.value.filter((s) => s.id !== stanza.id)
        selectedStanzas.value = selectedStanzas.value.filter((s) => s.id !== stanza.id)
        totalStanzas.value = totalStanzas.value - 1
        if (
            (lazyParams.value.size * (lazyParams.value.page - 1) + stanzas.value.length) < totalStanzas.value &&
            stanzas.value.length < lazyParams.value.size
        ) {
          loadStanzas(toRaw(lazyParams.value))
        }
      }).catch((error) => {
        //TODO: toast with error
      })
      close()
    }

    // @todo: add backend patch operation for bulk deletion?
    const onDeleteSelectedStanzas = (close) => {
      const stanzaIds = selectedStanzas.value.map((s) => s.id)
      Promise.all(stanzaIds.map((id) => api.stanzas.delete(id))).then(() => {
        stanzas.value = stanzas.value.filter((s) => !stanzaIds.includes(s.id))
        selectedStanzas.value = selectedStanzas.value.filter((s) => !stanzaIds.includes(s.id))
        totalStanzas.value = totalStanzas.value - stanzaIds.length
        loadStanzas(toRaw(lazyParams.value))
        close()
      }).catch((error) => {
        // @todo: toast with error
      })
    }

    const getOrderBy = (sortField, sortOrder) => {
      return sortField + (sortOrder === -1 ? '_desc' : '')
    }
    const defaultSortField = ref('updated_at')
    const defaultSortOrder = ref(-1)

    const loading = ref(false)
    const lazyParams = ref({})
    const dt = ref()
    const selectAll  = ref(false)
    const selectedStanzas = ref([])
    const stanzas = ref([])
    const pageSize = ref(10)
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

    const loadStanzas = async (params) => {
      loading.value = true
      params = Object.assign({}, params)
      // Load ahead some stanzas so don't have to refetch
      // on every deletion
      // @todo: better name. ahead, ahead_size?
      params.extra = 5
      await api.stanzas.list(params).then(result => {
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
          // @todo: alternatively { ...lazyParams.value } ?
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
        selectAll.value = false
        selectedStanzas.value = []
      }
    }
    const onRowSelect = () => {
      selectAll.value = selectedStanzas.value.length === totalStanzas.value
    }
    const onRowUnselect = () => {
      selectAll.value = false
    }

    watch(
      () => lazyParams,
      async newParams => {
        await loadStanzas(toRaw(newParams.value))
      },
      //{ immediate: true, deep: true }
      { deep: true }
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
      onDeleteStanza,
      onDeleteSelectedStanzas,
      dialogBreakpoints,
      dt
    }
  },
  components: {
    StanzaList,
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
        :to="{ name: 'CreateStanza', query: { destination: '/stanzas'} }"
        v-slot="{ navigate }"
      >
        <Button label="New" icon="pi pi-plus" class="p-button-success mr-2" @click="navigate"/>
      </router-link>
      <ConfirmDialogButton
        label="Delete"
        icon="pi pi-trash"
        class="p-button-danger"
        :breakpoints="dialogBreakpoints"
        @accept="onDeleteSelectedStanzas"
        :disabled="!selectedStanzas || !selectedStanzas.length"
      >
        <i class="pi pi-exclamation-triangle mr-3 p-confirm-dialog-icon" />
        <template #header>
          Confirm delete selection
        </template>
        <span class="p-confirm-dialog-message">Are you sure you want to delete selected stanzas?</span>
      </ConfirmDialogButton>

    </template>
  </Toolbar>

  <DataTable
    :value="stanzas"
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
    v-model:selection="selectedStanzas"
    v-model:expandedRows="expandedRows"
    :selectAll="selectAll"
    @select-all-change="onSelectAllChange"
    @row-select="onRowSelect"
    @row-unselect="onRowUnselect"
    resonsiveLayout="scroll"
    :totalRecords="totalStanzas"
    paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown" :rowsPerPageOptions="[10,25,50]"
    currentPageReportTemplate="Showing {first} to {last} of {totalRecords} stanzas"
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
    <Column style="min-with: 8rem">
      <template #body="{ data }">
        <div class="flex">
          <router-link
            custom
            :to="{ name: 'EditStanza', params: { id: data.id }, query: { destination: '/stanzas'} }"
            v-slot="{ navigate }"
          >
            <Button icon="pi pi-pencil" class="p-button-text p-button-info" @click="navigate"/>
          </router-link>
          <ConfirmDialogButton
            icon="pi pi-trash"
            class="p-button-text p-button-warning"
            :breakpoints="dialogBreakpoints"
            @accept="onDeleteStanza(data, $event)"
          >
            <i class="pi pi-exclamation-triangle mr-3 p-confirm-dialog-icon" />
            <template #header>
              Confirm delete
            </template>
            <span class="p-confirm-dialog-message">Are you sure you want to delete stanza<b>"{{data.name}}"</b>?</span>
          </ConfirmDialogButton>
        </div>
      </template>
    </Column>
    <template #expansion="{ data }">
      <div class="grid">
        <div class="col-12">{{ data.body }}</div>
      </div>
    </template>
  </DataTable>
</template>

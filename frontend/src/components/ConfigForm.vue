<script>
import {inject, toRef, ref, toRaw, watch, onMounted, computed} from 'vue'
import {useForm} from 'vee-validate'
import VTextField from '@/components/VTextField.vue'
import VColorPickerField from '@/components/VColorPickerField.vue'
import EntitySelect from '@/components/EntitySelect.vue'
import DataTable from 'primevue/datatable'
import { FilterMatchMode } from 'primevue/api'
import Column from 'primevue/column'
import Toolbar from 'primevue/toolbar'
import ConfirmDialogButton from '@/components/ConfirmDialogButton.vue'
import ChangeStanzaRevisionDialogButton from '@/components/ChangeStanzaRevisionDialogButton.vue'
import Dialog from 'primevue/dialog'

export default {
  emits: ['submit'],
  props: {
    config: {
      type: Object,
      required: true
    },
  },
  setup({ config }, { emit }) {

    const configValues = toRaw(config)

    const {handleSubmit, isSubmitting, useFieldModel, errors} = useForm({
      //validationSchema: schema,
      initialValues: {
        ...configValues
      }
    })

    const configStanzaRevisions = useFieldModel('stanza_revisions')

    const stanzas = ref([])
    const api = inject('api')
    const defaultSortField = ref('updated_at')
    const defaultSortOrder = ref(-1)
    const expandedRows = ref([])

    const onSubmit = handleSubmit((values, context) => {
      values.stanza_revisions = values.stanza_revisions.map( stanza_revision => stanza_revision.id );
      emit('submit', values, context)
    })

    const stanzaSelectFilterColumns = [
      {
        fieldName: 'name',
        filterFieldName: 'name',
        header: 'Name'
      }, {
        fieldName: 'user.name',
        filterFieldName: 'user_name',
        header: 'Created by'
      }
    ]

    const filters = ref({
      'name': {value: null, matchMode: FilterMatchMode.CONTAINS},
      'user.name': {value: null, matchMode: FilterMatchMode.CONTAINS}
    })

    // TODO: remove
    const filterMatchModeOptions = [
      { label: 'Contains', value: FilterMatchMode.CONTAINS },
      { label: 'Equals', value: FilterMatchMode.EQUALS },
    ]

    const loading = ref(false)
    const lazyParams = ref({})
    const totalStanzas = ref()
    const selectedStanzas = ref([])
    const selectedConfigStanzas = ref([])
    const pageSize = ref(50)

    watch(
      () => configStanzaRevisions,
      (newConfigStanzas) => {
        if (newConfigStanzas.value.length) {
          lazyParams.value.id_not_in = newConfigStanzas.value.map(
            (stanza_revision) => stanza_revision.id
          ).join(',')
        }
        else {
          delete lazyParams.value.id_not_in
        }
      },
      { immediate: true, deep: true }
    )

    const loadStanzas = (params) => {
      console.log('loading')
      console.dir(params)
      loading.value = true
      api.stanza_revisions.list(params).then(result => {
        stanzas.value = result.data
        totalStanzas.value = result.total
        loading.value = false
      })
    }

    const loadStanzasUnpaginated = async () => {
      // @todo: alternatively { ...lazyParams.value } ?
      let params = Object.assign({}, lazyParams.value)
      delete params.page
      delete params.size
      let result = await api.stanza_revisions.list(params)
      return result.data
    }

    // TODO: Kludge
    const getOrderBy = (sortField, sortOrder) => {
      return sortField + (sortOrder === -1 ? '_desc' : '')
    }

    //TODO: Default sort by new
    const onSort = (event) => {
      lazyParams.value['order_by'] = getOrderBy(event.sortField, event.sortOrder)
    }

    const onPage = (event) => {
      lazyParams.value.size = event.rows
      lazyParams.value.page = event.page + 1
    }

    const onFilter = (filters) => {
      for (const [filter_name, value] of Object.entries(filters)) {
        if (value.length) {
          lazyParams.value[filter_name] = value
        }
        else {
          delete lazyParams.value[filter_name]
        }
      }
    }

    const displayAddStanzasModal = ref(false)
    const openAddStanzasModal = () => {
      displayAddStanzasModal.value = true
    }

    const closeAddStanzasModal = () => {
      displayAddStanzasModal.value = false
    }

    const addStanzas = () => {
      configStanzaRevisions.value = configStanzaRevisions.value.concat(selectedStanzas.value)
      selectedStanzas.value = []
      closeAddStanzasModal()
    }

    const onSetStanzaRevision = (newRevision) => {
      let i = configStanzaRevisions.value.findIndex(
        revision => revision.stanza_id === newRevision.value.stanza_id
      )
      configStanzaRevisions.value[i] = newRevision.value
    }

    //TODO: current_revision_id should be used??
    const onRemoveSelectedStanzas = (close) => {
      let ids = []
      for (const stanza of selectedConfigStanzas.value) {
        ids[stanza.id] = true
      }
      configStanzaRevisions.value = configStanzaRevisions.value.filter((entity) => !ids[entity.id])
      selectedStanzas.value = []
      close()
    }

    const dialogBreakpoints = ref({
      '960px': '75vw',
      '640px': '90vw'
    })

    onMounted(() => {
      loading.value = true
      lazyParams.value.page = 1
      lazyParams.value.size = pageSize.value
      lazyParams.value.order_by = getOrderBy(defaultSortField.value, defaultSortOrder.value)
      lazyParams.value.is_current_revision = true
    })

    watch(
      () => lazyParams,
      async newParams => {
        await loadStanzas(toRaw(newParams.value))
      },
      { deep: true }
    )

    return {
      stanzas,
      configStanzaRevisions,
      totalStanzas,
      pageSize,
      loading,
      selectedStanzas,
      selectedConfigStanzas,
      expandedRows,
      defaultSortField,
      defaultSortOrder,
      onSort,
      onPage,
      onFilter,
      filters,
      stanzaSelectFilterColumns,
      loadStanzasUnpaginated,
      onSubmit,
      isSubmitting,
      errors,
      filterMatchModeOptions,
      openAddStanzasModal,
      closeAddStanzasModal,
      addStanzas,
      displayAddStanzasModal,
      onRemoveSelectedStanzas,
      onSetStanzaRevision,
      dialogBreakpoints
    }
  },
  components: {
    Dialog,
    Toolbar,
    DataTable,
    Column,
    ConfirmDialogButton,
    ChangeStanzaRevisionDialogButton,
    VTextField,
    VColorPickerField,
    EntitySelect
  }
}
</script>
<template>
  <form>
    <label for="name" class="block text-900 font-medium mb-2">Name</label>
    <VTextField id="name" name="name"/>

    <label for="color" class="block text-900 font-medium mb-2">Color</label>
    <VColorPickerField id="color" name="color"/>

    <label for="stanzas" class="block text-900 font-medium mb-2">Stanzas</label>
    <Toolbar class="mb-4" id="stanzas">
      <template #start>
        <Button
          label="Add stanzas"
          icon="pi pi-external-link"
          @click="openAddStanzasModal"
          class="p-button-success mr-2"
          :disabled="!stanzas.length"
        />
        <Dialog
          header="Add stanzas"
          v-model:visible="displayAddStanzasModal"
          :breakpoints="dialogBreakpoints"
          :maximizable="true"
          :draggable="false"
          :modal="true"
        >
          <EntitySelect
            v-model:entities="stanzas"
            v-model:selectedEntities="selectedStanzas"
            :pageSize="pageSize"
            :totalEntities="totalStanzas"
            :loading="loading"
            :defaultSortField="defaultSortField"
            :defaultSortOrder="defaultSortOrder"
            @sort="onSort($event)"
            @page="onPage($event)"
            @filter="onFilter($event)"
            :filterColumns="stanzaSelectFilterColumns"
            :loadEntitiesUnpaginated="loadStanzasUnpaginated"
          >
            <Column field="updated_at" header="Updated" :sortable="true"/>
          </EntitySelect>

          <template #footer>
            <Button type="button" label="Cancel" icon="pi pi-times" @click="closeAddStanzasModal" class="p-button-text" />
            <Button type="button" label="Add" icon="pi pi-plus" @click="addStanzas"/>
          </template>
        </Dialog>
        <ConfirmDialogButton v-if="configStanzaRevisions.length"
          label="Remove stanzas"
          icon="pi pi-trash"
          class="p-button-danger"
          :breakpoints="dialogBreakpoints"
          @accept="onRemoveSelectedStanzas"
          :disabled="!selectedConfigStanzas.length"
        >
          <i class="pi pi-exclamation-triangle mr-3 p-confirm-dialog-icon" />
          <template #header>
            Confirm removal
          </template>
          <span class="p-confirm-dialog-message">Are you sure you want to remove selected stanzas?</span>
        </ConfirmDialogButton>
      </template>
    </Toolbar>

    <DataTable v-if="configStanzaRevisions.length"
      :value="configStanzaRevisions"
      :rows="pageSize"
      dataKey="id"
      :sortField="defaultSortField"
      :sortOrder="defaultSortOrder"
      filterDisplay="row"
      v-model:filters="filters"
      v-model:selection="selectedConfigStanzas"
      v-model:expandedRows="expandedRows"
      resonsiveLayout="stack"
      breakpoint="640px"
      paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
      :rowsPerPageOptions="[10,25,50]"
      currentPageReportTemplate="Showing {first} to {last} of {totalRecords} entities"
    >
      <Column selectionMode="multiple" headerStyle="width: 3em"/>
      <Column :expander="true" headerStyle="width: 3em"/>
      <Column
        header="Name"
        field="name"
        filterMatchMode="startsWith"
        :filterMatchModeOptions="filterMatchModeOptions"
        :sortable="true"
      >
        <template #filter="{ filterModel, filterCallback }">
          <InputText type="text" v-model="filterModel.value" @keydown.enter="filterCallback()" placeholder="Search"/>
        </template>
      </Column>
      <Column
        header="User"
        field="user.name"
        filterMatchMode="startsWith"
        :filterMatchModeOptions="filterMatchModeOptions"
        :sortable="true"
      >
        <template #filter="{ filterModel, filterCallback }">
          <InputText type="text" v-model="filterModel.value" @keydown.enter="filterCallback()" placeholder="Search"/>
        </template>
      </Column>
      <Column field="updated_at" header="Updated" :sortable="true"/>
      <Column field="id" header="Revision" :sortable="false">
        <template #body="{ data }">
          <span :class="{'text-green-700': data.is_current_revision}">{{ data.id }}</span>
        </template>
      </Column>

      <Column>
        <template #body="{ data }">
          <div class="flex">
            <ChangeStanzaRevisionDialogButton
              icon="pi pi-pencil"
              class="p-button-text p-button-info"
              :breakpoints="dialogBreakpoints"
              :currentRevision="data"
              @accept="onSetStanzaRevision"
            >
              <i class="pi pi-exclamation-triangle mr-3 p-confirm-dialog-icon" />
              <template #header>
                Confirm delete
              </template>
              <span class="p-confirm-dialog-message">Are you sure you want to delete {{ entityName }}<b>"{{data.name}}"</b>?</span>
            </ChangeStanzaRevisionDialogButton>
          </div>
        </template>
      </Column>

      <template #expansion="{ data }">
        <div class="grid">
          <div class="col-12">{{ data.body }}</div>
        </div>
      </template>

    </DataTable>
    <Button type="button" :disabled="isSubmitting" @click="onSubmit" label="Save"></Button>
  </form>
</template>

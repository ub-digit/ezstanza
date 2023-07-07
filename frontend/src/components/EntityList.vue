<script>
import { computed, inject, toRef, ref, unref, toRaw, watch, onMounted } from 'vue' //watch currently unused
import { FilterMatchMode } from 'primevue/api'
import Column from 'primevue/column'
import Button from 'primevue/button'
import Toolbar from 'primevue/toolbar'
import MultiSelect from 'primevue/multiselect'
import ConfirmDialogButton from '@/components/ConfirmDialogButton.vue'
import EntitySelect from '@/components/EntitySelect.vue'
import UseEntityDataTable from '@/components/UseEntityDataTable.js'
import UseUserColumn from '@/components/UseUserColumn.js'
import CreateEntityButton from '@/components/CreateEntityButton.vue'

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
    },
    filters: {
      type: Object,
      default: {}
    },
    revisioned: {
      type: Boolean,
      default: true
    },
    userColumn: {
      type: Boolean,
      default: true
    },
    selectable: {
      type: Boolean,
      default: true
    },
    filterDisplay: {
      type: String,
      default: "row"
    },
    params: {
      type: Object,
      default: {}
    },
    lazy: {
      type: Boolean,
      default: true
    }
  },
  setup(props, context) {

    const dayjs = inject('dayjs')
    const api = inject('api')
    const defaultSortField = toRef(props, 'defaultSortField')
    const defaultSortOrder = ref(-1) //TODO: Use prop?
    const loading = ref(false)
    //const entities = ref([])
    //const totalEntities = ref()
    const selectedEntities = ref([])
    const pageSize = ref(10)

    const params = toRef(props, 'params') // TODO: WTF?
    const { entities, totalEntities, loadEntitiesUnpaginated, dataTableEvents } = UseEntityDataTable({
      lazy: props.lazy,
      loading: loading,
      params: params,
      entityNamePluralized: props.entityNamePluralized,
      pageSize: pageSize.value,
      defaultSortField: defaultSortField.value,
      defaultSortOrder: defaultSortOrder.value
    })

    const expandableRows = computed(() => context.slots.expansion !== undefined)

    const filters = toRef(props, 'filters')
    const { userColumnAttributes, userMultiSelectAttributes } = props.userColumn ?
      UseUserColumn({ filters, revisioned: props.revisioned }) :
      { userColumnAttributes: {}, userMultiSelectAttributes: {}, userOptions: null }

    // @todo: useBreakpoints?
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
        // TODO: Skip if not lazy?
        totalEntities.value = totalEntities.value - 1 //Maybe need to place this first
    }).catch((error) => {
        //TODO: toast with error
      })
      close()
    }

    // @todo: add backend patch operation for bulk deletion?
    const onDeleteSelectedEntities = (close) => {
      const selectedEntityIds = selectedEntities.value.map((s) => s.id)
      Promise.all(selectedEntityIds.map((id) => api[props.entityNamePluralized].delete(id))).then(() => {
        entities.value = entities.value.filter((s) => !selectedEntityIds.includes(s.id))
        selectedEntities.value = selectedEntities.value.filter((s) => !selectedEntityIds.includes(s.id))
        totalEntities.value = totalEntities.value - selectedEntityIds.length // maybe need to place first
        close()
      }).catch((error) => {
        // @todo: toast with error
      })
    }

    const entityLabel = computed(() => props.entityName.replace('_', ' '))
    const entityLabelPluralized = computed(() => props.entityNamePluralized.replace('_', ' '))

    return {
      dayjs,
      entities,
      totalEntities,
      pageSize,
      loading,
      selectedEntities,
      defaultSortField,
      defaultSortOrder,
      dataTableEvents,
      onDeleteEntity,
      onDeleteSelectedEntities,
      dialogBreakpoints,
      loadEntitiesUnpaginated,
      expandableRows,
      filters,
      //userField,
      //userFilterField,
      //userSortField,
      userColumnAttributes,
      userMultiSelectAttributes,
      entityLabel,
      entityLabelPluralized
    }
  },
  components: {
    EntitySelect,
    Column,
    Button,
    Toolbar,
    MultiSelect,
    ConfirmDialogButton,
    CreateEntityButton
  }
}
</script>
<template>
  <Toolbar class="mb-4">
    <template #start>
      <CreateEntityButton :createRouteName="createRouteName" :destinationPath="destinationPath"/>
      <ConfirmDialogButton
        v-if="selectable"
        label="Delete"
        icon="pi pi-trash"
        class="p-button-danger"
        :breakpoints="dialogBreakpoints"
        @accept="onDeleteSelectedEntities"
        :disabled="!selectedEntities || !selectedEntities.length"
      >
        <i class="pi pi-exclamation-triangle mr-3 p-confirm-dialog-icon" />
        <template #header>Confirm deletion</template>
        <span class="p-confirm-dialog-message">
          Are you sure you want to delete selected {{ entityLabelPluralized }}?
        </span>
      </ConfirmDialogButton>
    </template>
  </Toolbar>
  <EntitySelect
    :entities="entities"
    v-model:selectedEntities="selectedEntities"
    :pageSize="pageSize"
    :totalEntities="totalEntities"
    :loading="loading"
    :defaultSortField="defaultSortField"
    :defaultSortOrder="defaultSortOrder"
    v-on="dataTableEvents"
    :filterDisplay="filterDisplay"
    :filterColumns="filterColumns"
    :filters="filters"
    :loadEntitiesUnpaginated="loadEntitiesUnpaginated"
    :selectable="selectable"
    :lazy="lazy"
  >
    <template v-for="(_, name) in $slots" v-slot:[name]="slotData"><slot :name="name" v-bind="slotData" /></template>
    <template #reserved>
      <Column field="updated_at" header="Updated" :sortable="true">
        <template #body="{ data }">
          {{ dayjs(data.updated_at).format('L LT') }}
        </template>
      </Column>
      <Column
        v-if="userColumn"
        header="Updated by"
        v-bind="userColumnAttributes"
      >
        <template #filter="{filterModel, filterCallback}">
          <MultiSelect
            v-model="filterModel.value"
            @change="filterCallback()"
            v-bind="userMultiSelectAttributes"
          />
        </template>
      </Column>
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
              <span class="p-confirm-dialog-message">Are you sure you want to delete {{ entityLabel }} "{{data.name}}"?</span>
            </ConfirmDialogButton>
          </div>
        </template>
      </Column>
    </template>
  </EntitySelect>
</template>

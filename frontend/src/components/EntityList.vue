<script>
import { computed, inject, toRef, ref, unref, toRaw, watch, onMounted } from 'vue' //watch currently unused
import { FilterMatchMode } from 'primevue/api'
import Column from 'primevue/column'
import Button from 'primevue/button'
import Toolbar from 'primevue/toolbar'
import MultiSelect from 'primevue/multiselect'
import ConfirmDialogButton from '@/components/ConfirmDialogButton.vue'
import EntitySelect from '@/components/EntitySelect.vue'
import useEntityDataTable from '@/components/UseEntityDataTable.js'
import UseUserColumn from '@/components/UseUserColumn.js'
import CreateEntityButton from '@/components/CreateEntityButton.vue'

export default {
  //inhertiAttrs: false, // for v-bind="$attrs", multiple v-bind https://github.com/vuejs/rfcs/issues/550
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
      type: Object
    },
    lazy: {
      type: Boolean,
      default: true
    }
  },
  setup(props, context) {

    const dayjs = inject('dayjs')
    const api = inject('api')
    const selection = ref([])

    const entityLabel = computed(() => props.entityName.replace('_', ' '))
    const entityLabelPluralized = computed(() => props.entityNamePluralized.replace('_', ' '))

    const {
      entities,
      dataTableEvents,
      dataTableProperties,
      pageSize,
      totalRecords,
      loadEntitiesUnpaginated,
    } = useEntityDataTable({
      lazy: props.lazy,
      params: props.params,
      entityNamePluralized: props.entityNamePluralized,
      entityLabelPluralized: entityLabelPluralized.value, //TODO ??
      defaultPageSize: 10, //@TODO: prop with default value?
      defaultSortField: props.defaultSortField,
      defaultSortOrder: -1 //@TODO: prop with default value?
    })

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
        selection.value = selection.value.filter((s) => s.id !== entity.id)
        // TODO: Skip if not lazy?
        totalRecords.value = totalRecords.value - 1 //Maybe need to place this first
    }).catch((error) => {
        //TODO: toast with error
      })
      close()
    }

    // @todo: add backend patch operation for bulk deletion?
    const onDeleteSelectedEntities = (close) => {
      const selectedEntityIds = selection.value.map((s) => s.id)
      Promise.all(selectedEntityIds.map((id) => api[props.entityNamePluralized].delete(id))).then(() => {
        entities.value = entities.value.filter((s) => !selectedEntityIds.includes(s.id))
        selection.value = selection.value.filter((s) => !selectedEntityIds.includes(s.id))
        totalRecords.value = totalRecords.value - selectedEntityIds.length // maybe need to place first
        close()
      }).catch((error) => {
        // @todo: toast with error
      })
    }

    return {
      dayjs,
      entities,
      pageSize,
      selection,
      dataTableEvents,
      dataTableProperties,
      onDeleteEntity,
      onDeleteSelectedEntities,
      dialogBreakpoints,
      loadEntitiesUnpaginated,
      filters,
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
        :disabled="!selection || !selection.length"
      >
        <i class="pi pi-exclamation-triangle mr-3 p-confirm-dialog-icon" />
        <template #header>Confirm deletion</template>
        <span class="p-confirm-dialog-message">
          Are you sure you want to delete selected {{ entityLabelPluralized }}?
        </span>
      </ConfirmDialogButton>
    </template>
  </Toolbar>

  <slot name="header"></slot>

  <!-- TODO: v-bind $attrs? -->
  <EntitySelect
    :entities="entities"
    v-model:selection="selection"
    v-model:pageSize="pageSize"
    v-on="dataTableEvents"
    v-bind="dataTableProperties"
    :filterDisplay="filterDisplay"
    :filterColumns="filterColumns"
    :filters="filters"
    :loadEntitiesUnpaginated="loadEntitiesUnpaginated"
    :selectable="selectable"
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

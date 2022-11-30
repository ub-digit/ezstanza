<script>
import { computed, inject, toRef, ref, unref, toRaw, watch, onMounted } from 'vue'
import { FilterMatchMode } from 'primevue/api'
import Column from 'primevue/column'
import Button from 'primevue/button'
import Toolbar from 'primevue/toolbar'
import MultiSelect from 'primevue/multiselect'
import ConfirmDialogButton from '@/components/ConfirmDialogButton.vue'
import EntitySelect from '@/components/EntitySelect.vue'


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
      type: Object
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
    lazy: {
      type: Boolean,
      default: true
    }
  },
  setup(props, context) {

    const dayjs = inject('dayjs')
    const api = inject('api')
    const defaultSortField = toRef(props, 'defaultSortField')
    const defaultSortOrder = ref(-1)
    const loading = ref(false)
    const lazyParams = ref({})
    const entities = ref([])
    const totalEntities = ref()
    const selectedEntities = ref([])
    const pageSize = ref(10)

    const expandableRows = context.slots.expansion !== undefined

    const userOptions = ref([])
    api.users.list().then(result => {
      userOptions.value = result.data.map(
        user => {
          return {
            name: user.name,
            id: user.id
          }
        }
      )
    })

    const userField = computed(() => {
      return props.revisioned ? 'revision_user.name' : 'user.name';
    })
    const userFilterField = computed(() => {
      return props.revisioned ? 'revision_user_ids' : 'user_ids';
    })
    const userSortField = computed(() => {
      return props.revisioned ? 'revision_user_name' : 'user_name';
    })

    // TODO: Ugly, breaks reactivity, solve by settable computed?
    const filters = ref(toRaw(props.filters) || {})
    Object.assign(filters.value, {
      [toRaw(userFilterField.value)]: {
        matchMode: FilterMatchMode.EQUALS,
        value: ''
      }
    })

    // @todo: ugly, how to use defined standard breakpoints?
    const dialogBreakpoints = ref({
      '960px': '75vw',
      '640px': '90vw'
    })

    const loadEntities = (params) => {
      loading.value = true
      params = Object.assign({}, unref(params))
      // Load ahead some entities so don't have to refetch
      // on every deletion
      // @todo: better name. ahead, ahead_size?
      if (props.lazy) {
        params.extra = 5
      }
      api[props.entityNamePluralized].list(params).then(result => {
        entities.value = result.data
        totalEntities.value = 'total' in result? result.total : result.data.length
        loading.value = false
      })
    }

    const loadEntitiesUnpaginated = async () => {
      // @todo: alternatively { ...lazyParams.value } ?
      let params = Object.assign({}, unref(lazyParams))
      delete params.page
      delete params.size
      let result = await api[props.entityNamePluralized].list(params)
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
      if (props.lazy) {
        for (const [filter_name, value] of Object.entries(filters)) {
          if (typeof value !== 'string' || value.length) { // Hmm??
            lazyParams.value[filter_name] = value
          }
          else {
            delete lazyParams.value[filter_name]
          }
        }
      }
    }

    onMounted(() => {
      // TODO: rename lazyParams
      lazyParams.value = props.lazy ? {
        page: 1,
        //size: dt.value.rows,
        size: pageSize.value,
        order_by: getOrderBy(defaultSortField.value, defaultSortOrder.value)
      } : {}
    })

    const maybeLoadEntities = () => {
      if (
        props.lazy &&
          (lazyParams.value.size * (lazyParams.value.page - 1) + entities.value.length) < totalEntities.value &&
          entities.value.length < lazyParams.value.size
      ) {
        loadEntities(lazyParams)
      }
    }

    // Event handler with closure on entity
    const onDeleteEntity = (entity, close) => {
      // TODO: Delete from selected entities
      api[props.entityNamePluralized].delete(entity.id).then(() => {
        entities.value = entities.value.filter((s) => s.id !== entity.id)
        selectedEntities.value = selectedEntities.value.filter((s) => s.id !== entity.id)
        // TODO: Skip if not lazy?
        totalEntities.value = totalEntities.value - 1
        maybeLoadEntities()
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
        totalEntities.value = totalEntities.value - selectedEntityIds.length

        maybeLoadEntities()
        close()
      }).catch((error) => {
        // @todo: toast with error
      })
    }

    watch(
      () => lazyParams,
      async newParams => {
        await loadEntities(newParams)
      },
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
    const entityLabel = computed(() => props.entityName.replace('_', ' '))
    const entityLabelPluralized = computed(() => props.entityNamePluralized.replace('_', ' '))

    return {
      dayjs,
      userOptions,
      entities,
      totalEntities,
      pageSize,
      loading,
      selectedEntities,
      defaultSortField,
      defaultSortOrder,
      onSort,
      onPage,
      onFilter,
      onDeleteEntity,
      onDeleteSelectedEntities,
      dialogBreakpoints,
      loadEntitiesUnpaginated,
      expandableRows,
      filters,
      userField,
      userFilterField,
      userSortField,
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
        v-if="selectable"
        label="Delete"
        icon="pi pi-trash"
        class="p-button-danger"
        :breakpoints="dialogBreakpoints"
        @accept="onDeleteSelectedEntities"
        :disabled="!selectedEntities || !selectedEntities.length"
      >
        <i class="pi pi-exclamation-triangle mr-3 p-confirm-dialog-icon" />
        <template #header>
          Confirm deletion
        </template>
        <span class="p-confirm-dialog-message">Are you sure you want to delete selected {{ entityLabelPluralized }}?</span>
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
    @sort="onSort($event)"
    @page="onPage($event)"
    @filter="onFilter($event)"
    :filterDisplay="filterDisplay"
    :filterColumns="filterColumns"
    :filters="filters"
    :loadEntitiesUnpaginated="loadEntitiesUnpaginated"
    :selectable="selectable"
    :lazy="lazy"
  >
    <template v-for="(_, name) in $slots" v-slot:[name]="slotData"><slot :name="name" v-bind="slotData" /></template>
    <template #reserved>
      <!-- TODO: format date -->
      <Column field="updated_at" header="Updated" :sortable="true">
        <template #body="{ data }">
          {{ dayjs(data.updated_at).format('L LT') }}
        </template>
      </Column>
      <Column
        v-if="userColumn"
        :field="userField"
        header="Updated by"
        :sortable="true"
        :sortField="userSortField"
        :filterField="userFilterField"
        :showFilterMenu="false"
      >
        <template #filter="{filterModel, filterCallback}">
          <MultiSelect
            v-model="filterModel.value"
            @change="filterCallback()"
            :options="userOptions"
            optionLabel="name"
            optionValue="id"
            placeholder="Any"
            display="chip"
            class="p-column-filter"
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

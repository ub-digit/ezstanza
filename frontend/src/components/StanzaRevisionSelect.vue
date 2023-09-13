<script>
import { ref, toRef, inject, watch } from 'vue'

import Column from 'primevue/column'
import MultiSelect from 'primevue/multiselect'
import EntitySelect from '@/components/EntitySelect.vue'
import UseEntityDataTable from '@/components/UseEntityDataTable.js'
import UseUserColumn from '@/components/UseUserColumn.js'

export default {
  emits: ['update:modelValue', 'update:loading'],
  //inheritAttrs: false,
  props: {
    loading: {
      type: Boolean,
      default: true,
    },
    modelValue: {
      type: Array,
      default: [],
    },
    params: {
      type: Object,
      default: {}
    }
  },
  setup(props, { emit }) {

    const dayjs = inject('dayjs')
    const loading = ref(true)
    const pageSize = ref(5)
    const defaultSortField = ref('updated_at')
    const defaultSortOrder = ref(-1)
    const { entities, totalEntities, loadEntitiesUnpaginated, dataTableEvents } = UseEntityDataTable({
      lazy: true,
      loading: loading,
      params: props.params,
      entityNamePluralized: 'stanza_revisions',
      pageSize: pageSize.value,
      defaultSortField: defaultSortField.value,
      defaultSortOrder: defaultSortOrder.value
    })

    watch(loading, (newLoading) => {
      emit('update:loading', newLoading)
    })

    const filterColumns = ref([
      {
        fieldName: 'name',
        filterFieldName: 'name',
        header: 'Name'
      }
    ])

    const filters = ref({})
    //TODO: pass loading?
    const { userColumnAttributes, userMultiSelectAttributes } = UseUserColumn({ filters, revisioned: false })

    return {
      dayjs,
      entities,
      loading,
      pageSize, //?
      defaultSortField,
      defaultSortOrder,
      totalEntities,
      loadEntitiesUnpaginated,
      dataTableEvents,
      filters,
      filterColumns,
      userColumnAttributes,
      userMultiSelectAttributes
    }
  },
  components: {
    EntitySelect,
    MultiSelect,
    Column
  }
}

</script>
<template>
  <!-- v-model instead of v-model:selectedEntities? -->
  <EntitySelect
    :entities="entities"
    :selectedEntities="modelValue"
    @update:selectedEntities="$emit('update:modelValue', $event)"
    :pageSize="pageSize"
    :totalEntities="totalEntities"
    :loading="loading"
    :defaultSortField="defaultSortField"
    :defaultSortOrder="defaultSortOrder"
    v-on="dataTableEvents"
    filterDisplay="row"
    :filterColumns="filterColumns"
    :filters="filters"
    :loadEntitiesUnpaginated="loadEntitiesUnpaginated"
    :selectable="true"
    :lazy="true"
  >
    <template v-for="(_, name) in $slots" v-slot:[name]="slotData"><slot :name="name" v-bind="slotData" /></template>
    <template #reserved>
      <Column field="updated_at" header="Updated" :sortable="true">
        <template #body="{ data }">
          {{ dayjs(data.updated_at).format('L LT') }}
        </template>
      </Column>
      <Column
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
    </template>
  </EntitySelect>
</template>

<style>
</style>

<script>
import {ref, inject} from 'vue'
import { useRoute } from 'vue-router'
import EntityList from '@/components/EntityList.vue'
import Column from 'primevue/column'
import ColorChip from '@/components/ColorChip.vue'
import MultiSelect from 'primevue/multiselect'
import { FilterMatchMode } from 'primevue/api'

export default {
  setup() {
    // @todo: format date
    // const route = useRoute()
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

    const api = inject('api')
    const configOptions = ref([])

    api.configs.list().then(result => {
      configOptions.value = result.data.map(
        config => {
          return {
            name: config.name,
            id: config.id
          }
        }
      )
    })

    const filterColumns = [
      {
        fieldName: 'name',
        filterFieldName: 'name',
        header: 'Name'
      }
    ]

    const filters = {
      config_ids: {
        matchMode: FilterMatchMode.EQUALS,
        value: ''
      }
    }

    return {
      filterColumns,
      filters,
      configOptions
    }
  },
  components: {
    EntityList,
    Column,
    ColorChip,
    MultiSelect
  }
}
</script>
<template>
  <EntityList
    createRouteName="CreateStanza"
    editRouteName="EditStanza"
    destinationPath="/stanzas"
    entityName="stanza"
    entityNamePluralized="stanzas"
    defaultSortField="updated_at"
    :filterColumns="filterColumns"
    :filters="filters"
    :revisioned="true"
  >
    <Column
      field="current_configs"
      header="Configs"
      :sortable="false"
      filterField="config_ids"
      :showFilterMenu="false"
    >
      <template #filter="{filterModel, filterCallback}">
        <MultiSelect
          v-model="filterModel.value"
          @change="filterCallback()"
          :options="configOptions"
          optionLabel="name"
          optionValue="id"
          placeholder="Any"
          display="chip"
          class="p-column-filter"
        />
      </template>
      <template #body="{ data }">
        <ColorChip
          v-for="config in data.current_configs"
          :key="config.id"
          :color="config.color"
          class="mb-2"
          :class="{ 'has-previous-revision': !config.has_current_stanza_revision }"
        >
          {{ config.name }}
        </ColorChip>
      </template>
    </Column>
    <template #expansion="{ data }">
      <div class="grid">
        <div class="col-12">{{ data.body }}</div>
      </div>
    </template>
  </EntityList>
</template>
<style lang="scss" scoped>
.p-chip.has-previous-revision {
  opacity: 0.4;
}
</style>

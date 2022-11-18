<script>
import { useRoute } from 'vue-router'
import EntityList from '@/components/EntityList.vue'
import Column from 'primevue/column'
import Chip from 'primevue/chip'

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
    const filterColumns = [
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
    return {
      filterColumns
    }
  },
  components: {
    EntityList,
    Column,
    Chip
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
  >
    <Column field="current_configs" header="Configs" :sortable="false">
      <template #body="{ data }">
        <Chip
          v-for="config in data.current_configs"
          :key="config.id"
          class="mb-2"
          :class="{ 'has-current-revision': config.has_current_stanza_revision }"
          removable
        >
          {{ config.name }}
        </Chip>
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
.p-chip.has-current-revision {
  background: var(--primary-color);
  color: var(--primary-color-text);
}
</style>

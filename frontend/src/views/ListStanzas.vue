<script>
import { useRoute } from 'vue-router'
import EntityList from '@/components/EntityList.vue'
import Column from 'primevue/column'
import ColorChip from '@/components/ColorChip.vue'

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
    ColorChip
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

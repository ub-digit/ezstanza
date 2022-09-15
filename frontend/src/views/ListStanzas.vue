<script>
import { useRoute } from 'vue-router'
import EntityList from '@/components/EntityList.vue'

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
    EntityList
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
    <template #expansion="{ data }">
      <div class="grid">
        <div class="col-12">{{ data.body }}</div>
      </div>
    </template>
  </EntityList>
</template>

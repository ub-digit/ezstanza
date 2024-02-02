<script>
import { useRoute } from 'vue-router'
import EntityList from '@/components/EntityList.vue'
import { FilterMatchMode } from 'primevue/api'

export default {
  setup() {
    const filterColumns = [
      {
        fieldName: 'name',
        filterFieldName: 'name',
        header: 'Name',
        defaultFilterMatchMode: FilterMatchMode.CONTAINS
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
    createRouteName="CreateTag"
    editRouteName="EditTag"
    destinationPath="/tags"
    entityName="tag"
    entityNamePluralized="tags"
    defaultSortField="updated_at"
    :filterColumns="filterColumns"
    :revisioned="false"
  >
  </EntityList>
</template>

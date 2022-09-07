<script>
import { useRoute } from 'vue-router'
import EntityList from '@/components/EntityList.vue'

export default {
  setup() {
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
    createRouteName="CreateTag"
    editRouteName="EditTag"
    destinationPath="/tags"
    entityName="tag"
    entityNamePluralized="tags"
    defaultSortField="updated_at"
    :filterColumns="filterColumns"
  >
  </EntityList>
</template>

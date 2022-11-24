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
    createRouteName="CreateConfig"
    editRouteName="EditConfig"
    destinationPath="/configs"
    entityName="config"
    entityNamePluralized="configs"
    defaultSortField="updated_at"
    :filterColumns="filterColumns"
    :revisioned="true"
  >
  </EntityList>
</template>

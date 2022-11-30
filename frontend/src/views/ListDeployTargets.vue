<script>
import { useRoute } from 'vue-router'
import EntityList from '@/components/EntityList.vue'
import Column from 'primevue/column'

export default {
  setup() {
    const filterColumns = [
      /*
      {
        fieldName: 'name',
        filterFieldName: 'name',
        header: 'Name'
        }
        */  
    ]
    return {
      filterColumns
    }
  },
  components: {
    EntityList,
    Column
  }
}
</script>
<template>
  <!-- fix entityNamePluralized, used for service endpoint which should be separate property or override with fallback to pluralized -->
  <EntityList
    createRouteName="CreateDeployTarget"
    editRouteName="EditDeployTarget"
    destinationPath="/deploy_targets"
    entityName="deploy_target"
    entityNamePluralized="deploy_targets"
    defaultSortField="updated_at"
    :filterColumns="filterColumns"
    filterDisplay="menu"
    :userColumn="false"
    :revisioned="false"
    :selectable="false"
    :lazy="false"
  >
    <Column field="name" header="Name" :sortable="true"/>
  </EntityList>
</template>

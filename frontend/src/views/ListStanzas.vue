<script>
import {ref} from 'vue'
import { useRoute } from 'vue-router'
import EntityList from '@/components/EntityList.vue'
import Column from 'primevue/column'
import StanzaCurrentDeployment from '@/components/StanzaCurrentDeployment.vue'
//import ConfigsDropDown from '@/components/ConfigsDropDown.vue'
import DeployTargetsDropDown from '@/components/DeployTargetsDropDown.vue'
import DropDown from 'primevue/dropdown'
import { FilterMatchMode } from 'primevue/api'

import Button from 'primevue/button'

export default {
  setup() {

    const filterColumns = ref([
      {
        fieldName: 'name',
        filterFieldName: 'name',
        header: 'Name'
      }
    ])

    const filters = ref({
      deployment_ids: {
        matchMode: FilterMatchMode.EQUALS,
        value: null
      }
    })

    return {
      filterColumns,
      filters
    }
  },
  components: {
    EntityList,
    Column,
    StanzaCurrentDeployment,
    DeployTargetsDropDown, //TODO: UsersDropDown?
    DropDown,
    Button
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
      field="revision_id"
      header="Revision id"
      :sortable="false"
    >
    </Column>
    <Column
      header="Deployments"
      field="current_deployments"
      filterField="deployment_ids"
      :showFilterMenu="false"
      :sortable="false"
    >
      <template #filter="{filterModel, filterCallback}">
        <DeployTargetsDropDown
          placeholder="Any"
          class="p-column-filter"
          v-model="filterModel.value"
          optionValue="id"
          @change="filterCallback()"
        />
      </template>
      <template #body="{ data }">
        <div class="flex flex-column align-items-start gap-2">
          <StanzaCurrentDeployment
            v-for="deployment in data.current_deployments"
            :deployment="deployment.deployment"
            :stanzaRevision="deployment.stanza_revision"
          />
        </div>
      </template>
    </Column>

    <template #expansion="{ data }">
      <div class="grid">
        <pre class="col-12">{{ data.body }}</pre>
      </div>
    </template>
  </EntityList>
</template>
<style lang="scss" scoped>
.p-chip.has-previous-revision {
  opacity: 0.4;
}
</style>

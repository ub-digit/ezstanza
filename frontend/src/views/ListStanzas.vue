<script>
import {ref} from 'vue'
import { useRoute } from 'vue-router'
import EntityList from '@/components/EntityList.vue'
import Column from 'primevue/column'
import StanzaCurrentDeployment from '@/components/StanzaCurrentDeployment.vue'
import StanzaCurrentConfigChip from '@/components/StanzaCurrentConfigChip.vue' //@FIXME: Rename, without Chip?
import ConfigsDropDown from '@/components/ConfigsDropDown.vue'
import DropDown from 'primevue/dropdown'
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

    const filterColumns = [
      {
        fieldName: 'name',
        filterFieldName: 'name',
        header: 'Name'
      }
    ]

    const filters = {
      config_id: {
        matchMode: FilterMatchMode.EQUALS,
        value: null
      }
    }

    return {
      filterColumns,
      filters
    }
  },
  components: {
    EntityList,
    Column,
    StanzaCurrentConfigChip,
    StanzaCurrentDeployment,
    ConfigsDropDown, //TODO: UsersDropDown?
    DropDown
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
      field="current_configs"
      header="Configs"
      :sortable="false"
      filterField="config_id"
      :showFilterMenu="false"
    >
      <template #filter="{filterModel, filterCallback}">
        <ConfigsDropDown
          placeholder="Any"
          class="p-column-filter"
          v-model="filterModel.value"
          optionValue="id"
          @change="filterCallback()"
        />
      </template>
      <template #body="{ data }">
        <div class="flex flex-column align-items-start gap-2">
          <StanzaCurrentConfigChip
            v-for ="config in data.current_configs"
            :currentConfig="config"
            :currentStanzaRevisionId="data.revision_id"
          />
        </div>
      </template>
    </Column>
    <Column
      field="current_deployments"
      header="Deployments"
      :sortable="false"
    >
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

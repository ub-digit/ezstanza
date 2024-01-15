<script>
import { ref, inject } from 'vue'
import { useRoute } from 'vue-router'
import EntityList from '@/components/EntityList.vue'
import Column from 'primevue/column'
import StanzaCurrentDeployment from '@/components/StanzaCurrentDeployment.vue'
import MultiSelect from 'primevue/multiselect'
import AutoComplete from 'primevue/autocomplete'
import CustomAutoComplete from '@/components/CustomAutoComplete.vue'
import { FilterMatchMode } from 'primevue/api'
import Tag from 'primevue/tag'

import Button from 'primevue/button'

export default {
  setup() {

    const filterColumns = ref([
      {
        fieldName: 'name',
        filterFieldName: 'search_query',
        header: 'Name',
        showFilterMenu: false,
        filterMatchModes: []
      }
    ])

    const filters = ref({
      deployment_ids: {
        matchMode: FilterMatchMode.EQUALS,
        value: null
      },
      tag_ids: {
        matchMode: FilterMatchMode.EQUALS,
        value: []
      }
    })

    const deploymentsfilterMatchModeOptions = [
      { label: 'Equals', value: FilterMatchMode.EQUALS },
      { label: 'Not equals', value: FilterMatchMode.NOT_EQUALS }
    ]

    // More or less duplicate code, use-module for this?
    const api = inject('api')
    const tags = ref([])
    // TODO: Fetch only tags currently used for stanzas
    api.tags.list().then(result => {
      tags.value = result.data.map(tag => {
        return {
          id: tag.id,
          name: tag.name
        }
      })
    })

    const tagSuggestions = ref([])
    const searchTags = (event) => {
      const query = event.query.trim()
      if (!query) {
        tagSuggestions.value = [...tags.value]
      } else {
        tagSuggestions.value = tags.value.filter((tag) => {
          return tag.name.toLowerCase().startsWith(query.toLowerCase())
        })
      }
    }

    const deployTargetOptions = ref([])
    api.deploy_targets.list().then(result => {
      deployTargetOptions.value = result.data.map(
        deployTarget => {
          let id = deployTarget.current_deployment ?
            deployTarget.current_deployment.id : -1;
          return {
            name: deployTarget.name,
            id: id
          }
        }
      )
    })

    return {
      filterColumns,
      filters,
      tags,
      tagSuggestions,
      searchTags,
      FilterMatchMode,
      deploymentsfilterMatchModeOptions,
      deployTargetOptions
    }
  },
  components: {
    EntityList,
    Column,
    StanzaCurrentDeployment,
    CustomAutoComplete,
    MultiSelect,
    Button,
    Tag
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
      :showFilterMenu="true"
      :sortable="false"
      :filterMatchModeOptions="deploymentsfilterMatchModeOptions"
    >
      <template #filter="{filterModel, filterCallback}">
        <MultiSelect
          placeholder="Any"
          class="p-column-filter"
          v-model="filterModel.value"
          @change="filterCallback()"
          :options="deployTargetOptions"
          optionLabel="name"
          optionValue="id"
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
    <Column
      header="Tags"
      field="tags"
      filterField="tag_ids"
      :showFilterMenu="false"
      :sortable="false"
    >
      <template #filter="{filterModel, filterCallback}">
        <CustomAutoComplete
          dropdown
          v-model="filterModel.value"
          :options="tags"
          :suggestions="tagSuggestions"
          optionLabel="name"
          optionValue="id"
          @change="filterCallback()"
          @complete="searchTags"
        />
      </template>
      <template #body="{ data }">
        <div class="flex flex-column align-items-start gap-2">
          <Tag  v-for="tag in data.tags" :value="tag.name"/>
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

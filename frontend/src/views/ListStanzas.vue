<script>
import { ref, reactive, inject, watch, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import Column from 'primevue/column'
import Fieldset from 'primevue/fieldset';
import MultiSelect from 'primevue/multiselect'
import Dropdown from 'primevue/dropdown'
import AutoComplete from 'primevue/autocomplete'
import InputText from 'primevue/inputtext'
import Checkbox from 'primevue/checkbox'
import Tag from 'primevue/tag'
import { FilterMatchMode } from 'primevue/api'
import { useToast } from 'primevue/usetoast'
import { ToastSeverity } from 'primevue/api'
import EntityList from '@/components/EntityList.vue'
import CustomAutoComplete from '@/components/CustomAutoComplete.vue'
import StanzaCurrentDeployment from '@/components/StanzaCurrentDeployment.vue'

import Button from 'primevue/button'

export default {
  setup() {
    /*
    const filterColumns = ref([
      {
        fieldName: 'name',
        filterFieldName: 'search_query',
        header: 'Name',
        showFilterMenu: false,
        filterMatchModes: []
      }
    ])
     */

    const toast = useToast()
    const toastTimeout = 5000

    const filterColumns = ref([])

    const filters = ref({
      deployment_ids: {
        matchMode: FilterMatchMode.EQUALS,
        value: null
      },
      disabled: {
        matchMode: FilterMatchMode.EQUALS,
        value: null
      },
      tag_ids: {
        matchMode: FilterMatchMode.EQUALS,
        value: []
      },
      name: {
        matchMode: FilterMatchMode.CONTAINS,
        value: null,
      },
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

    const params = reactive({
      disabled: null,
      search_query: null
    })
    const searchQuery = ref()

    const setSearchQuery = () => {
      params.search_query = searchQuery.value
    }

    const isDisabledOptions = ref([
      {
        label: 'Any',
        value: null
      },
      {
        label: 'Yes',
        value: true
      }, {
        label: 'No',
        value: false
      }
    ])

    const { deployment: deploymentChannel } = inject('channels')
    let channelRef = null
    onMounted(() => {
      channelRef = deploymentChannel.on('deployment_status_change', payload => {
        if (payload.status === 'completed') {
          // TODO: Perhaps check user and only notify if deployed by
          // current user?
          entityList.value.reload()
          toast.add({
            severity: ToastSeverity.INFO,
            summary: "Deployment successful",
            detail: "Stanza was successfully deployed",
            life: toastTimeout
          })
        }
        else if(payload.status === 'failed') {
          toast.add({
            severity: ToastSeverity.ERROR,
            summary: "Deployment failed",
            detail: "Stanza deployment failed",
            life: toastTimeout
          })
        }
      })
    })
    onUnmounted(() => {
      deploymentChannel.off('deployment_status_change', channelRef)
    })
    const entityList = ref()

    return {
      entityList,
      filterColumns,
      filters,
      params,
      tags,
      tagSuggestions,
      searchTags,
      FilterMatchMode,
      deploymentsfilterMatchModeOptions,
      deployTargetOptions,
      isDisabledOptions,
      searchQuery,
      setSearchQuery
    }
  },
  components: {
    EntityList,
    Column,
    StanzaCurrentDeployment,
    CustomAutoComplete,
    MultiSelect,
    Dropdown,
    InputText,
    Button,
    Checkbox,
    Tag,
    Fieldset
  }
}
</script>
<template>
  <EntityList
    ref="entityList"
    createRouteName="CreateStanza"
    editRouteName="EditStanza"
    destinationPath="/stanzas"
    entityName="stanza"
    entityNamePluralized="stanzas"
    defaultSortField="updated_at"
    :filterColumns="filterColumns"
    :filters="filters"
    :params="params"
    :revisioned="true"
  >
    <template #header>
      <Fieldset legend="Additional filters" :toggleable="true" :collapsed="true">
        <div class="field">
          <label for="disabled" class="block text-900 font-medium mb-2">Disabled</label>
          <Dropdown
            placeholder="Any"
            id="disabled"
            v-model="params.disabled"
            :options="isDisabledOptions"
            optionLabel="label"
            optionValue="value"
          />
        </div>
        <div class="field">
          <div class="flex flex-column gap-2">
            <label for="fulltext-search">Fulltext search</label>
            <InputText
              style="width: 500px;"
              id="fulltext-search"
              v-model="searchQuery"
              @keydown.enter="setSearchQuery"
              aria-describedby="fulltext-search-help"
            />
            <small id="fulltext-search-help">Search name and stanza content.</small>
          </div>
        </div>
      </Fieldset>
    </template>

    <Column
      field="name"
      filterField="name"
      sortField="name"
      header="Name"
      :showFilterMenu="false"
      :sortable="true"
    >
      <template #filter="{ filterModel, filterCallback }">
        <InputText
          type="text"
          v-model="filterModel.value"
          @keydown.enter="filterCallback()"
          placeholder="Search"
          class="mb-2"
        />
        <!--
        <Checkbox v-model="fulltextSearch" inputId="fulltext-search" :binary="true" />
        <label for="fulltext-search" class="ml-2">Include stanza</label>
        -->
      </template>
      <template #body="{ field, data }">
        {{ data[field] }}
        <span v-if="data.disabled">
          (Disabled)
        </span>
      </template>
    </Column>

    <Column
      field="weight"
      header="Weight"
      :sortable="true"
    >
    </Column>

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

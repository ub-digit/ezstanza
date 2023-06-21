<script>
import { ref, unref, toRaw, inject, watch, computed, onUnmounted } from 'vue'
import ColorChip from '@/components/ColorChip.vue'
import DeploymentStatus from '@/components/DeploymentStatus.vue'
import Toolbar from 'primevue/toolbar'
import DropDown from 'primevue/dropdown'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Dialog from 'primevue/dialog'
import { FilterMatchMode } from 'primevue/api'
import UseLazyDataTable from '@/components/UseLazyDataTable.js'
import useOnSubmit from '@/components/UseOnEntityFormSubmit.js'
import { useForm } from 'vee-validate'

import { Socket } from "phoenix"
//import { useAuth } from '@websanova/vue-auth/src/v3.js'

//TODO: User filter
//TODO: reset filters on create new?

export default {
  props: {
  },
  setup() {

    const loading = ref(false)
    const dayjs = inject('dayjs')
    const api = inject('api')
    const socket = inject('socket')
    const dt = ref() //TODO: Unused, remove?

    const deployments = ref([])
    const totalDeployments = ref(0)
    const pageSize = ref(25)
    const defaultSortField = ref('inserted_at')
    const defaultSortOrder = ref(-1)

    const dialogBreakpoints = ref({
      '960px': '75vw',
      '640px': '90vw'
    })
    const {handleSubmit, isSubmitting, setFieldValue} = useForm({
      //validationSchema: schema,
      initialValues: {
        deploy_target_id: null,
        config_revision_id: null,
      }
    })

    const createDeploymentDialogVisible = ref(false)
    const openCreateDeploymentDialog = () => {
      createDeploymentDialogVisible.value = true
    }
    const closeCreateDeploymentDialog = () => {
      createDeploymentDialogVisible.value = false
      deployTarget.value = null
    }

    const afterHideCreateDeploymentDialog = () => {
      deployTarget.value = null
    }

    //const auth = useAuth()
    //TODO process.env.VUE_APP_SOCKET_URL
    //TODO: useSocket, takes token, returning singleton?
    //const socket = new Socket('ws://127.0.0.1:4000/socket', {params: {token: auth.token()}})
    //console.log('connecting')
    //console.dir({params: {token: auth.token()}})
    //socket.connect()
    const channel = socket.channel("deployment", {})
    channel.on("deployment_status_change", payload => {
      const deployment = deployments.value.find(deployment => deployment.id === payload.id)
      deployment.status = payload.status
    })
    channel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", resp => { console.log("Unable to join", resp) })

    onUnmounted(() => {
      channel.leave()
        .receive("ok", resp => { console.log("Left successfully", resp) })
        .receive("error", resp => { console.log("Unable to leae", resp) }) // Does this even exists?
    })

    //const onDeploymentSubmit = useOnSubmit('deployment', 'deployments', 'create')
    const onSubmit = handleSubmit((deployment, { setErrors, resetForm }) => {
      /* create:deployment? */
      channel.push("create_deployment", deployment)
        .receive("ok", payload => {
          console.log("create deployment reply", payload)
          resetForm()
          deployments.value.unshift(payload) //Or reload all?
          closeCreateDeploymentDialog()
        })
        .receive("error", err => {
          if (err.data && err.data.errors) {
            setErrors(err.data.errors)
          }
          else {
            console.dir(err)
            //TOOD: Toast??
          }
        })
        .receive("timeout", () => console.log('timeout pushing, toast?'))
      /*
      onDeploymentSubmit(deployment, context).then((deployment) => {
        deployments.value.unshift(deployment) //Or reload all?
        closeCreateDeploymentDialog()
      })
      */
    })

    const { lazyParams, dataTableEvents } = UseLazyDataTable({
      pageSize: pageSize.value,
      defaultSortField: defaultSortField.value,
      defaultSortOrder: defaultSortOrder.value
    })

    //TODO: Forgot to add user to migration
    const filters = ref({
      config_id: {value: null, matchMode: FilterMatchMode.EQUALS},
      deploy_target_id: {value: null, matchMode: FilterMatchMode.EQUALS},
      user_id: {value: null, matchMode: FilterMatchMode.EQUALS}
      //config_revision_id?
    })

    const filterMatchModeOptions = [
      { label: 'Contains', value: FilterMatchMode.CONTAINS },
      { label: 'Equals', value: FilterMatchMode.EQUALS },
    ]

    //TODO deployTargetId?
    const deployTarget = ref()
    const deployTargets = ref([])
    // TODO: error handling
    api.deploy_targets.list().then(results => {
      deployTargets.value = results.data // convert to options? TODO: skip convert to options in other places?
    })
    const config = ref()
    const configs = ref([])

    api.configs.list({ includes: ['revisions'] }).then(result => {
      configs.value = result.data
    })

    //TODO: Find out how to set/get object instead
    watch(deployTarget, (newDeployTarget) => {
      setFieldValue('deploy_target_id', newDeployTarget ? newDeployTarget.id : null)
      if (newDeployTarget) {
        config.value = configs.value.find(
          config => config.id === newDeployTarget.default_config_id
        )
      }
      else {
        config.value = null
      }
    })

    const configRevision = ref()
    const configRevisions = ref([])
    watch(config, (newConfig) => {
      if (newConfig) {
        configRevisions.value = config.value.revisions
        configRevision.value = config.value.revisions.find(revision => revision.is_current_revision)
      }
      else {
        configRevisions.value = []
        configRevision.value = null
      }
    })

    watch(configRevision, (newConfigRevision) => {
      setFieldValue('config_revision_id', newConfigRevision ? newConfigRevision.id : null)
    })

    // Or inline in watch since only called once?
    const loadDeployments = (params) => {
      loading.value = true
      // TODO: error handling
      api.deployments.list(toRaw(unref(params))).then(result => {
        deployments.value = result.data
        totalDeployments.value = result.total
        loading.value = false
      })
    }

    watch(
      () => lazyParams,
      async newParams => {
        await loadDeployments(newParams)
      },
      { deep: true }
    )

    // Hide paginator if all entities are currently displayed
    const showPaginator = computed(() => {
      // Feature not a but that page size not reacative
      // since don't want to hide pagination if first
      // visiable even if increasing page size to fit all
      // entities
      return totalDeployments.value > pageSize.value
    })
    /*
    const onCreateDeploymentDialogClose = () => {
      resetForm()
    }
     */

    return {
      dt,
      deployTarget,
      deployTargets,
      config,
      configs,
      configRevisions,
      configRevision,
      deployments,
      totalDeployments,
      pageSize,
      showPaginator,
      filters,
      dataTableEvents,
      defaultSortField,
      defaultSortOrder,
      dayjs,
      onSubmit,
      isSubmitting,
      openCreateDeploymentDialog,
      closeCreateDeploymentDialog,
      createDeploymentDialogVisible,
      dialogBreakpoints,
      afterHideCreateDeploymentDialog,
      loading
    }
    /* TODO:
       - Get deploy targets
       - Get config revisions for deploy targets (update on selection)
       - Save button
    */
  },
  components: {
    Toolbar,
    DropDown,
    DataTable,
    Column,
    ColorChip,
    Dialog,
    DeploymentStatus
  }
}
</script>
<template>
  <Toolbar>
    <template #start>
      <Button
        label="Create"
        class="p-button-success"
        @click="openCreateDeploymentDialog"
      />
      <Dialog
        v-model:visible="createDeploymentDialogVisible"
        :modal="true"
        @after-hide="afterHideCreateDeploymentDialog"
        class="p-confirm-dialog"
        :closeOnEscape="true"
        :breakpoints="dialogBreakpoints"
      >
        <template #header>
          Create deployment
        </template>
        <form @submit="onSubmit">
          <!-- TODO: inline form layout -->
          <label for="deploy-target" class="block text-900 font-medium mb-2">Deploy target</label>
          <DropDown
            id="deploy-target"
            v-model="deployTarget"
            :options="deployTargets"
            dataKey="id"
            optionLabel="name"
            placeholder="Select deploy target"
            class="mb-5"
          />
          <template v-if="config">
            <label for="config" class="block text-900 font-medium mb-2">Config</label>
            <DropDown
              id="config"
              v-model="config"
              :options="configs"
              dataKey="id"
              optionLabel="name"
              placeholder="Select config"
              class="mb-5"
            />
            <label for="config-revision" class="block text-900 font-medium mb-2">Config revision</label>
            <DropDown
              id="config-revision"
              v-model="configRevision"
              :options="configRevisions"
              dataKey="id"
              placeholder="Select config revision"
              class="mb-5"
            >
              <template #option="{ option }">
                <span :class="{'text-green-700': option.is_current_revision}">
                  Revision: {{ option.id }}
                </span>
                ({{ dayjs(option.updated_at).format('L LT') }})
              </template>
              <template #value="slotProps">
                <template v-if="slotProps.value">
                  <span :class="{'text-green-700': slotProps.value.is_current_revision}">
                    Revision: {{ slotProps.value.id }}
                  </span>
                  ({{ dayjs(slotProps.value.updated_at).format('L LT') }})
                </template>
                <template v-else>
                  {{ slotProps.placeholder }}
                </template>
              </template>
            </DropDown>
            <Button v-if="configRevision" type="submit" :disabled="isSubmitting" label="Deploy"></Button>
          </template>
        </form>
      </Dialog>
    </template>
  </Toolbar>
  <!-- TODO: Make deployed config revision viewable in UI? and/or difference from current? -->
  <DataTable
    :value="deployments"
    :lazy="true"
    :paginator="showPaginator"
    :rows="pageSize"
    ref="dt"
    dataKey="id"
    :sortField="defaultSortField"
    :sortOrder="defaultSortOrder"
    v-on="dataTableEvents"
    filterDisplay="row"
    v-model:filters="filters"
    resonsiveLayout="scroll"
    :totalRecords="totalDeployments"
    paginatorTemplate="FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown"
    :rowsPerPageOptions="[10,25,50]"
    currentPageReportTemplate="Showing {first} to {last} of {totalRecords} entities"
    :loading="loading"
  >
    <Column field="inserted_at" header="Deploy date" :sortable="true"/>
    <Column field="status" header="Status" :sortable="true">
      <template #body="{ data: {status: status} }">
        <div class="text-center">
          <DeploymentStatus :status="status"/>
        </div>
      </template>
    </Column>
    <!--TODO filters -->
    <Column field="user.name" header="User" sortField="user_name" :sortable="true"/>
    <Column
      field="deploy_target.name"
      filterField="deploy_target_id"
      header="Deploy target"
      :showFilterMenu="false"
      :sortable="false"
    >
      <template #filter="{filterModel, filterCallback}">
        <DropDown
          placeholder="Any"
          v-model="filterModel.value"
          :options="deployTargets"
          optionLabel="name"
          optionValue="id"
          @change="filterCallback()"
          class="p-column-filter"
        />
      </template>
    </Column>
    <!-- TODO: does field prop actually matter here? -->
    <Column
      field="deploy_target.config_revision.name"
      filterField="config_id"
      header="Config"
      :sortable="false"
      :showFilterMenu="false"
    >
      <template #filter="{filterModel, filterCallback}">
        <DropDown
          placeholder="Any"
          v-model="filterModel.value"
          :options="configs"
          optionLabel="name"
          optionValue="id"
          @change="filterCallback()"
          class="p-column-filter"
        />
      </template>
      <template #body="{ data: {config_revision: revision} }">
        <ColorChip
          :color="revision.color"
          :label="revision.name"
          :class="{ 'is-previous-revision': !revision.is_current_revision }"
        />
      </template>
    </Column>
    <!-- TODO: field prop dito? -->
    <Column
      field="config_revision_id"
      header="Config revision id"
      :sortable="false"
    >
      <template #body="{ data: {config_revision: revision} }">
        <span :class="{'text-green-700': revision.is_current_revision}">
          {{ revision.id }}
        </span>
      </template>
    </Column>
  </DataTable>

</template>
<style scoped>
/* TODO: Component for this to avoid code duplication (in ListStanzas.vue) */
/* Probably better without this */
/*
.p-chip.is-previous-revision {
  opacity: 0.4;
}
*/
</style>

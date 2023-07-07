<script>
import { ref, unref, toRaw, inject, watch, computed, onUnmounted } from 'vue'
import ColorChip from '@/components/ColorChip.vue'
import DeploymentStatus from '@/components/DeploymentStatus.vue'
import Toolbar from 'primevue/toolbar'
import Panel from 'primevue/panel'
import DropDown from 'primevue/dropdown'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Dialog from 'primevue/dialog'
import { FilterMatchMode } from 'primevue/api'
import UseEntityDataTable from '@/components/UseEntityDataTable.js'
import useOnSubmit from '@/components/UseOnEntityFormSubmit.js'
import { useForm } from 'vee-validate'

//import StanzaRevisionSelectDialogButton from '@/components/StanzaRevisionSelectDialogButton.vue'
import StanzaRevisionPickList from '@/components/StanzaRevisionPickList.vue'

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

    //const deployments = ref([])
    //const totalDeployments = ref(0)
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

    const createDeploymentFormVisible = ref(false)
    const openCreateDeploymentDialog = () => {
      createDeploymentFormVisible.value = true
    }
    const closeCreateDeploymentDialog = () => {
      createDeploymentFormVisible.value = false
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

    const { entities: deployments, totalEntities: totalDeployments, dataTableEvents } = UseEntityDataTable({
      lazy: false,
      loading: loading,
      entityNamePluralized: 'deployments',
      pageSize: pageSize.value,
      defaultSortField: defaultSortField.value,
      defaultSortOrder: defaultSortOrder.value
    })

    const filters = ref({
      deploy_target_id: {value: null, matchMode: FilterMatchMode.EQUALS},
      user_id: {value: null, matchMode: FilterMatchMode.EQUALS}
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

    const addedStanzaRevisions = ref([])
    const addStanzaRevisionsParams = ref({
      is_current_revision: true
    })

    watch(addedStanzaRevisions, (newValue) => {
      console.log('selection changed', newValue)
      console.log('after change', addedStanzaRevisions)
    })

    //TODO: Find out how to set/get object instead
    watch(deployTarget, (newDeployTarget) => {
      setFieldValue('deploy_target_id', newDeployTarget ? newDeployTarget.id : null)

      if (newDeployTarget.current_deployment_id) {
        addStanzaRevisionsParams.value.deployment_id_not_equal = newDeployTarget.current_deployment_id
      }

      //Stage add new stanza revisions
      //When staging stanza, exclude by filter in lazy query

      //Stage modify stanza revision (add latest)

      //Stage delete stanza revisions
      // When staging stanza, exclude by filter in lazy query
    })

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
      createDeploymentFormVisible,
      dialogBreakpoints,
      afterHideCreateDeploymentDialog,
      addStanzaRevisionsParams,
      addedStanzaRevisions,
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
    DeploymentStatus,
    Panel,
    //StanzaRevisionSelectDialogButton,
    StanzaRevisionPickList
  }
}
</script>
<template>
  <Panel class="mb-4" toggleable header="Deploy">
    <form @submit="onSubmit">
      <div class="field">
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
      </div>
      <template v-if="deployTarget">
        <div class="field">
          <label for="stage-new-stanza-revisions" class="block text-900 font-medium mb-2">New stanzas</label>
          <StanzaRevisionPickList addLabel="Add" v-model="addedStanzaRevisions" :params="addStanzaRevisionsParams"/>
        </div>
        <Button type="submit" :disabled="isSubmitting" label="Deploy"></Button>
      </template>
    </form>
  </Panel>
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

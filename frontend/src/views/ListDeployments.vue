<script>
import { ref, unref, toRaw, inject, watch, computed, onUnmounted, onMounted } from 'vue'
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
//import StanzaRevisionSelect from '@/components/StanzaRevisionSelect.vue'
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
    const deploying = ref(false) // Bit of a hack
    const dayjs = inject('dayjs')
    const api = inject('api')
    const { deployment: deploymentChannel } = inject('channels')
    const dt = ref() //TODO: Unused, remove?

    //const deployments = ref([])
    //const totalDeployments = ref(0)
    const pageSize = ref(10)
    const defaultSortField = ref('inserted_at')
    const defaultSortOrder = ref(-1)

    const dialogBreakpoints = ref({
      '960px': '75vw',
      '640px': '90vw'
    })

    //TODO: VDropDown?
    const {handleSubmit, isSubmitting, setFieldValue, useFieldModel} = useForm({
      //validationSchema: schema,
      initialValues: {
        deploy_target: null
      }
    })

    const deployTarget = useFieldModel('deploy_target')
    var channelRef = null

    onMounted(() => {
      console.log('on mounted')
      channelRef = deploymentChannel.on("deployment_status_change", payload => {
        console.log('status change', payload)
        const deployment = deployments.value.find(deployment => deployment.id === payload.id)
        if (deployment) {
          deployment.status = payload.status
          if (["completed", "failed"].includes(payload.status)) {
            deploying.value = false
          }
          // Avoid race condition, ugly temporary? fix
          if (payload.status === "completed") {
            //TODO: Disable deploy target selection before completed
            fetchDeployTargets()
          }
        }
      })

      /*
      channel.join()
        .receive("ok", resp => { console.log("Joined successfully", resp) })
        .receive("error", resp => { console.log("Unable to join", resp) })
      */
    })
    onUnmounted(() => {
      console.log('on unmounted')
      deploymentChannel.off("deployment_status_change", channelRef)
      /*
      channel.leave()
        .receive("ok", resp => { console.log("Left successfully", resp) })
        .receive("error", resp => { console.log("Unable to leae", resp) }) // Does this even exists?
      */
    })

    //const onDeploymentSubmit = useOnSubmit('deployment', 'deployments', 'create')
    const onSubmit = handleSubmit((values, { setErrors, resetForm }) => {
      deploying.value = true
      /* create:deployment? */

      const deployment = {
        stanza_revision_changes:  [],
        stanza_deletions:  [],
        deploy_target_id: values.deploy_target.id,
        current_deployment_id: values.deploy_target.current_deployment.id
      }

      const revisionChange = (stanzaRevision) => {
          return { id: stanzaRevision.current_revision_id, stanza_id: stanzaRevision.stanza_id }
      }

      if (addStanzaRevisions.value.length) {
        deployment.stanza_revision_changes = toRaw(addStanzaRevisions.value).map(revisionChange)
      }

      if (editStanzaRevisions.value.length) {
        deployment.stanza_revision_changes = deployment.stanza_revision_changes.concat(
          toRaw(editStanzaRevisions.value).map(revisionChange)
        )
      }

      if (deleteStanzaRevisions.value.length) {
        deployment.stanza_deletions = toRaw(deleteStanzaRevisions.value).map(
          stanzaRevision => stanzaRevision.stanza_id
        )
      }

      console.log('channel request', deployment)

      deploymentChannel.push("create_deployment", deployment)
        .receive("ok", payload => {
          addStanzaRevisions.value = []
          editStanzaRevisions.value = []
          deleteStanzaRevisions.value = []
          resetForm()
          deployments.value.unshift(payload) //Or reload all?
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
    })

    const { entities: deployments, totalEntities: totalDeployments, dataTableEvents } = UseEntityDataTable({
      lazy: true,
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
    const deployTargets = ref([])
    // TODO: error handling

    const fetchDeployTargets = () => {
      api.deploy_targets.list().then(results => {
        deployTargets.value = results.data // convert to options? TODO: skip convert to options in other places?
      })
    }
    fetchDeployTargets()

    const addStanzaRevisions = ref([])
    const addStanzaRevisionsParams = ref({
      is_current_revision: true
    })

    const editStanzaRevisions = ref([])
    const editStanzaRevisionsParams = ref({
      is_current_revision: false
    })

    const deleteStanzaRevisions = ref([])
    const deleteStanzaRevisionsParams = ref({})

    watch(addStanzaRevisions, (newValue) => {
      console.log('selection changed', newValue)
      console.log('after change', addStanzaRevisions)
    })

    //TODO: Find out how to set/get object instead
    watch(deployTarget, (newDeployTarget) => {
      console.log('new deploy target', newDeployTarget)
      if (newDeployTarget && newDeployTarget.current_deployment && newDeployTarget.current_deployment.id) {
        addStanzaRevisionsParams.value.deployment_id_not_equals = newDeployTarget.current_deployment.id
        editStanzaRevisionsParams.value.deployment_id = newDeployTarget.current_deployment.id
        deleteStanzaRevisionsParams.value.deployment_id = newDeployTarget.current_deployment.id
      }
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
      dialogBreakpoints,
      addStanzaRevisionsParams,
      addStanzaRevisions,
      editStanzaRevisionsParams,
      editStanzaRevisions,
      deleteStanzaRevisionsParams,
      deleteStanzaRevisions,
      deploying,
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
    //StanzaRevisionSelect,
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
          :disabled="deploying"
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
          <label for="add-stanza-revisions" class="block text-900 font-medium mb-2">Add new stanzas to deployment</label>
          <StanzaRevisionPickList addLabel="Add new" v-model="addStanzaRevisions" :params="addStanzaRevisionsParams"/>
          <template v-if="deployTarget.current_deployment.id">
            <label for="edit-stanza-revisions" class="block text-900 font-medium mb-2">Add modified stanzas to deployment</label>
            <StanzaRevisionPickList addLabel="Add modified" v-model="editStanzaRevisions" :params="editStanzaRevisionsParams"/>
            <label for="delete-stanza-revisions" class="block text-900 font-medium mb-2">Remove stanzas from deployment</label>
            <StanzaRevisionPickList addLabel="Remove" v-model="deleteStanzaRevisions" :params="deleteStanzaRevisionsParams"/>
          </template>
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
    <Column field="inserted_at" header="Deploy date" :sortable="true">
      <template #body="{ data }">
        {{ dayjs(data.inserted_at).format('L LT') }}
      </template>
    </Column>

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

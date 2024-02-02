<script>
import { ref, unref, toRaw, inject, watch, computed, onUnmounted, onMounted } from 'vue'
import ColorChip from '@/components/ColorChip.vue'
import DeploymentStatus from '@/components/DeploymentStatus.vue'
import DeploymentStanzaRevisions from '@/components/DeploymentStanzaRevisions.vue'
import Tooltip from '@/components/Tooltip.vue'
import DialogButton from '@/components/DialogButton.vue'
import StanzaRevisionPickList from '@/components/StanzaRevisionPickList.vue'
import useEntityDataTable from '@/components/UseEntityDataTable.js'
import useOnSubmit from '@/components/UseOnEntityFormSubmit.js'
import Toolbar from 'primevue/toolbar'
import Panel from 'primevue/panel'
import Dropdown from 'primevue/dropdown'
import Checkbox from 'primevue/checkbox'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Dialog from 'primevue/dialog'
import Divider from 'primevue/divider'
import { FilterMatchMode } from 'primevue/api'
import { useForm } from 'vee-validate'

import { Socket } from "phoenix"
//import { useAuth } from '@websanova/vue-auth/src/v3.js'

//TODO: User filter
//TODO: reset filters on create new?

export default {
  props: {
  },
  setup() {

    const deploying = ref(false) // Bit of a hack
    const dayjs = inject('dayjs')
    const api = inject('api')
    const { deployment: deploymentChannel } = inject('channels')
    const dt = ref() //TODO: Unused, remove?

    const dialogBreakpoints = ref({
      '960px': '75vw',
      '640px': '90vw'
    })

    //TODO: VDropdown?
    const {handleSubmit, isSubmitting, setFieldValue, useFieldModel} = useForm({
      //validationSchema: schema,
      initialValues: {
        deploy_target: null
      }
    })

    const deployTarget = useFieldModel('deploy_target')

    //const deployTargetT
    var channelRef = null

    onMounted(() => {
      console.log('on mounted')
      channelRef = deploymentChannel.on("deployment_status_change", payload => {
        console.log('status change', payload)
        const deployment = deployments.value.find(d => d.id === payload.id)
        if (deployment) {
          deployment.status = payload.status
          if (["completed", "failed"].includes(payload.status)) {
            deploying.value = false
          }
          // Avoid race condition, ugly temporary? fix
          if (payload.status === "completed") {
            // TODO: Super mega ugly hack
            const prevCurrentDeployment = deployments.value.find(
              (d) => {
                return d.is_current_deployment &&
                  d.deploy_target.id === deployment.deploy_target.id
              }
            )
            console.log('current old', prevCurrentDeployment)
            if (prevCurrentDeployment) {
              prevCurrentDeployment.is_current_deployment = false;
              // isCurrentDeployment filter is set
              if (isCurrentDeployment.value) {
                deployments.value = deployments.value.filter(d => d.id !== prevCurrentDeployment.id)
              }
            }
            deployment.is_current_deployment = true;
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
          //TODO: Should propbably do this after submitting deploy instead
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

    const {
      entities: deployments,
      dataTableEvents: dataTableEvents,
      dataTableProperties: dataTableProperties,
      lazyParams: lazyParams,
      pageSize: pageSize
    } = useEntityDataTable({
      lazy: true,
      entityNamePluralized: 'deployments',
      entityLabelPluralized: 'deployments',
      defaultPageSize: 10,
      defaultSortField: 'inserted_at',
      defaultSortOrder: -1
    })

    // Hack:
    //lazyParams.is_current_deployment = false;
    const isCurrentDeployment = ref(true)
    watch(isCurrentDeployment, (newValue) => {
      if (newValue) {
        lazyParams.value.is_current_deployment = true
      }
      else {
        delete lazyParams.value.is_current_deployment
      }
    }, { immediate: true })

    const filters = ref({
      status: {value: null, matchMode: FilterMatchMode.EQUALS},
      deploy_target_id: {value: null, matchMode: FilterMatchMode.EQUALS},
      user_id: {value: null, matchMode: FilterMatchMode.EQUALS}
    })

    // TODO: This is unused, review and perhaps remove?
    const filterMatchModeOptions = [
      { label: 'Contains', value: FilterMatchMode.CONTAINS },
      { label: 'Equals', value: FilterMatchMode.EQUALS }
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
      is_current_revision: true,
      disabled: false,
    })

    const editStanzaRevisions = ref([])
    const editStanzaRevisionsParams = ref({
      is_current_revision: false,
      disabled: false,
    })

    const deleteStanzaRevisions = ref([])
    const deleteStanzaRevisionsParams = ref({})


    const deployStanzaRevisionsAdded = computed(() => {
      console.log('computed run')
      return addStanzaRevisions.value.length ||
        editStanzaRevisions.value.length ||
        deleteStanzaRevisions.value.length
    })

    //TODO: Find out how to set/get object instead
    watch(deployTarget, (newDeployTarget) => {
      if (newDeployTarget && newDeployTarget.current_deployment && newDeployTarget.current_deployment.id) {
        addStanzaRevisionsParams.value.deployment_id_not_equal = newDeployTarget.current_deployment.id
        editStanzaRevisionsParams.value.deployment_id = newDeployTarget.current_deployment.id
        deleteStanzaRevisionsParams.value.deployment_id = newDeployTarget.current_deployment.id
      }
    })

    /*
    const onCreateDeploymentDialogClose = () => {
      resetForm()
    }
     */
    const statuses = ref([
      {
        name: 'Pending',
        value: 'pending'
      }, {
        name: 'Deploying',
        value: 'deploying'
      }, {
        name: 'Completed',
        value: 'completed'
      }, {
        name: 'Failed',
        value: 'failed'
      }
    ])

    return {
      dt,
      deployTarget,
      deployTargets,
      deployments,
      statuses,
      pageSize,
      filters,
      dataTableEvents,
      dataTableProperties,
      dayjs,
      onSubmit,
      isSubmitting,
      deployStanzaRevisionsAdded,
      dialogBreakpoints,
      addStanzaRevisionsParams,
      addStanzaRevisions,
      editStanzaRevisionsParams,
      editStanzaRevisions,
      deleteStanzaRevisionsParams,
      deleteStanzaRevisions,
      deploying,
      isCurrentDeployment
    }
    /* TODO:
       - Get deploy targets
       - Get config revisions for deploy targets (update on selection)
       - Save button
    */
  },
  components: {
    Toolbar,
    Dropdown,
    Checkbox,
    DataTable,
    Column,
    ColorChip,
    Dialog,
    DeploymentStatus,
    DeploymentStanzaRevisions,
    Tooltip,
    DialogButton,
    Panel,
    Divider,
    StanzaRevisionPickList
  }
}
</script>
<template>
  <Panel class="mb-4" toggleable header="Deploy">
    <form @submit="onSubmit">
      <div class="field">
        <label for="deploy-target" class="block text-900 font-medium mb-2">Deploy target</label>
        <Dropdown
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
        <Panel class="mb-4" :header="`Add new stanzas to ${deployTarget.name.toLowerCase()}`">
          <StanzaRevisionPickList
            openLabel="Add"
            dialogHeader="Add new stanzas"
            addLabel="Add"
            removeLabel="Remove"
            v-model="addStanzaRevisions"
            :params="addStanzaRevisionsParams"
          />
        </Panel>
        <template v-if="deployTarget.current_deployment.id">
          <Panel class="mb-4" :header="`Add modified stanzas to ${deployTarget.name.toLowerCase()}`">
            <StanzaRevisionPickList
              openLabel="Add"
              dialogHeader="Add modified stanzas"
              addLabel="Add"
              removeLabel="Remove"
              v-model="editStanzaRevisions"
              :params="editStanzaRevisionsParams"
            />
          </Panel>
          <Panel class="mb-4" :header="`Remove stanzas from ${deployTarget.name.toLowerCase()}`">
            <StanzaRevisionPickList
              openLabel="Add"
              dialogHeader="Add stanzas to be removed"
              addLabel="Add"
              removeLabel="Remove"
              v-model="deleteStanzaRevisions"
              :params="deleteStanzaRevisionsParams"
            />
          </Panel>
        </template>
        <Button
          type="submit"
          :disabled="isSubmitting || !deployStanzaRevisionsAdded"
          label="Deploy"
        />
      </template>
    </form>
  </Panel>
  <!-- TODO: Make deployed config revision viewable in UI? and/or difference from current? -->
  <DataTable
    :value="deployments"
    ref="dt"
    dataKey="id"
    v-on="dataTableEvents"
    v-bind="dataTableProperties"
    v-model:rows="pageSize"
    v-model:filters="filters"
    filterDisplay="row"
    resonsiveLayout="scroll"
    :rowsPerPageOptions="[10,25,50,100]"
    :rowClass="(data) => !data.is_current_deployment ? 'text-500' : null"
  >
    <template #header>
      <div class="field-checkbox">
        <Checkbox
          inputId="is-current-deployment"
          binary
          v-model="isCurrentDeployment"
        />
        <label for="is-current-deployment">Show only current deployments</label>
      </div>
    </template>
    <Column field="inserted_at" header="Deploy date" :sortable="true">
      <template #body="{ data }">
        {{ dayjs(data.inserted_at).format('L LT') }}
      </template>
    </Column>

    <Column
      field="status"
      header="Status"
      :sortable="true"
      filterField="status"
      :showFilterMenu="false"
    >
      <template #filter="{filterModel, filterCallback}">
        <Dropdown
          placeholder="Any"
          v-model="filterModel.value"
          :options="statuses"
          optionLabel="name"
          optionValue="value"
          @change="filterCallback()"
          class="p-column-filter"
        />
      </template>
      <template #body="{ data: {status: status, is_current_deployment: is_current} }">
        <div class="text-center">
          <DeploymentStatus :status="status"/>
          <Tooltip text="Currently deployed" v-slot="events" v-if="is_current">
            &nbsp;<i class="pi pi-cloud-upload" v-on="events"></i>
          </Tooltip>
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
        <Dropdown
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
    <Column style="min-with: 8rem">
      <template #body="{ data }">
        <Tooltip text="View stanzas" v-slot="events">
          <DialogButton
            v-on="events"
            icon="pi pi-file"
            class="p-button-text"
            :overflowFix="true"
            :breakpoints="dialogBreakpoints"
          >
            <template #header>
              Deployment stanzas
            </template>
            <DeploymentStanzaRevisions :deployment="data"/>
          </DialogButton>
        </Tooltip>
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

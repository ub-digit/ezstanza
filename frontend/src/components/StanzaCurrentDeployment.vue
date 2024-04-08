<script>
import { ref, inject, reactive, onMounted, onUnmounted } from 'vue'
import ColorChip from '@/components/ColorChip.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import OverlayPanel from 'primevue/overlaypanel'
import Tag from 'primevue/tag'
import useTextClassForBackground from '@/components/UseTextClassForBackground.js'
import { useToast } from 'primevue/usetoast'
import { ToastSeverity } from 'primevue/api'

export default {
  emits: ['removed'],
  props: {
    stanzaRevision: {
      type: Object,
      required: true
    },
    deployment: {
      type: Object,
      required: true
    }
  },
  setup({ deployment, stanzaRevision }, { emit }) {
    const dayjs = inject('dayjs')

    // TODO: How to set this globally?
    const toastTimeout = 3000
    const toast = useToast()

    const deploymentStanzaInfo = ref(null)
    const toggleDeploymentStanzaInfo = (event) => {
      deploymentStanzaInfo.value.toggle(event)
    }

    const showRemoveConfirmation = ref(false)
    const visible = ref(true)
    const removable = ref(true)
    const removeAndDeployDialogVisible = ref(false)
    const onRemoveAndDeploy = (event) => {
      removeAndDeployDialogVisible.value = true
    }

    // Possible race condition, this is a terrible solution but should work 99.99% of the time
    const { deployment: deploymentChannel } = inject('channels')
    let currentDeploymentId = null
    let channelRef = null
    onMounted(() => {
      channelRef = deploymentChannel.on('deployment_status_change', payload => {
        if(payload.id == currentDeploymentId) {
          if (payload.status === 'completed') {
            visible.value = false
            toast.add({
              severity: ToastSeverity.INFO,
              summary: "Deployment successful",
              detail: `Stanza "${stanzaRevision.name}" was successfully removed from ${deployment.deploy_target.name}`,
              life: toastTimeout
            })
            emit('removed', deployment)
          }
          else if(payload.status === 'failed') {
            toast.add({
              severity: ToastSeverity.ERROR,
              summary: "Deployment failed",
              detail: `Stanza "${stanzaRevision.name}" could not be removed from ${deployment.deploy_target.name} for an unkonwn reason`,
              life: toastTimeout
            })
          }
        }
      })
    })
    onUnmounted(() => {
      deploymentChannel.off('deployment_status_change', channelRef)
    })

    const onConfirmRemoveAndDeploy = (close) => {
      const deletionDeployment = {
        stanza_deletions: [stanzaRevision.stanza_id],
        deploy_target_id: deployment.deploy_target.id
      }
      deploymentChannel.push('create_deployment', deletionDeployment)
        .receive('ok', payload => {
          currentDeploymentId = payload.id
        })
        .receive('error', err => {
          if (err.data && err.data.errors) {
            console.dir(err.data.errors)
          }
          else {
            console.dir(err)
          }
        })
        .receive('timeout', () => console.log('timeout pushing, toast?'))
      removable.value = false
      close()
    }

    return {
      dayjs,
      deploymentStanzaInfo,
      toggleDeploymentStanzaInfo,
      removable,
      visible,
      removeAndDeployDialogVisible,
      onRemoveAndDeploy,
      onConfirmRemoveAndDeploy
    }
  },
  components: {
    ColorChip,
    Tag,
    OverlayPanel,
    ConfirmDialog
  }
}
</script>
<template>
  <ConfirmDialog v-model:visible="removeAndDeployDialogVisible" @accept="onConfirmRemoveAndDeploy">
    <template #header>
      Remove and deploy
    </template>
    <span class="p-confirm-dialog-message">
      Are you sure you want to remove this stanza and perform a new deployment?
    </span>
  </ConfirmDialog>
  <ColorChip :color="deployment.deploy_target.color" :removable="removable" @remove="onRemoveAndDeploy" :visible="visible">
    <i v-if="removable"
      :class="['p-chip-icon', 'pi', stanzaRevision.is_current_revision ? 'pi-check' : 'pi-info-circle', 'stanza-current-deployment-icon']"
      @mouseover="toggleDeploymentStanzaInfo"
      @mouseleave="toggleDeploymentStanzaInfo">
    </i>
    <i v-else class="p-chip-icon pi pi-spin pi-spinner">
    </i>
    <span class="p-chip-text">{{ deployment.deploy_target.name }}</span>
  </ColorChip>
  <OverlayPanel ref="deploymentStanzaInfo">
    <div class="flex flex-column align-items-start gap-2">
      <template v-if="stanzaRevision.is_current_revision">
        <Tag icon="pi pi-check-circle" class="align-self-start" severity="success">
          Current revision
        </Tag>
      </template>
      <template v-else>
        <Tag icon="pi pi-file" severity="info">
          Revision id: {{ stanzaRevision.id }}
        </Tag>
        <div v-if="stanzaRevision.log_message" class="text-sm">
          {{ stanzaRevision.log_message }}
        </div>
        <span class="text-xs">
          By: {{ stanzaRevision.user.name }}<br/>
          {{ dayjs(stanzaRevision.updated_at).format('L LT') }}
        </span>
      </template>
    </div>
  </OverlayPanel>
</template>
<style>
.stanza-current-deployment-icon:hover {
  cursor: pointer;
}
/*
.stanza-current-deployment .p-button.p-button-icon-only.p-button-rounded {
  width: 2rem;
  height: 2rem;
  margin: 0 0.5rem;
}
*/
</style>

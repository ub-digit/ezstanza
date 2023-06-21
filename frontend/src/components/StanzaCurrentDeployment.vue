<script>
import { ref, computed, inject } from 'vue'
import Chip from 'primevue/chip'
import useTextClassForBackground from '@/components/UseTextClassForBackground.js'

//import Button from 'primevue/button'
//import InfoCircleIcon from 'primevue/icons/infocircle'
import OverlayPanel from 'primevue/overlaypanel'
import SideBar from 'primevue/sidebar'
import Tag from 'primevue/tag'

export default {
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
  setup({ deployment }) {
    const dayjs = inject('dayjs')

    const deploymentStanzaInfo = ref(null)
    const toggleDeploymentStanzaInfo = (event) => {
      deploymentStanzaInfo.value.toggle(event)
    }

    const deploymentConfigInfo = ref(null)
    const toggleDeploymentConfigInfo = (event) => {
      deploymentConfigInfo.value.toggle(event)
    }

    const deploymentInfo = ref(null)
    const toggleDeploymentInfo = (event) => {
      deploymentInfo.value.toggle(event)
    }
    const deployedConfigTextColorClass = useTextClassForBackground(deployment.config_revision.color, 'text-black', 'text-white')
    //TODO: TextClass prefix also when used in ColorChip

    const isDeploymentInfoVisible = ref(false)

    return {
      dayjs,
      deploymentStanzaInfo,
      toggleDeploymentStanzaInfo,
      deploymentConfigInfo,
      toggleDeploymentConfigInfo,
      deploymentInfo,
      toggleDeploymentInfo,
      deployedConfigTextColorClass,
      isDeploymentInfoVisible
    }
  },
  components: {
    Chip,
    Tag,
    OverlayPanel,
    SideBar
  }
}
</script>
<template>
  <Chip>
    <i
      :class="['p-chip-icon', 'pi', stanzaRevision.is_current_revision ? 'pi-check' : 'pi-info-circle', 'stanza-current-deployment-icon']"
      @click="isDeploymentInfoVisible = true"
      @mouseover="toggleDeploymentStanzaInfo"
      @mouseleave="toggleDeploymentStanzaInfo">
    </i>
    <SideBar
      v-model:visible="isDeploymentInfoVisible"
      position="right"
    >
      ...
    </SideBar>
    <span class="p-chip-text">{{ deployment.deploy_target.name }}</span>
  </Chip>
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
      <span class="text-xs">
        <Tag
          v-if="deployment.config_revision.is_current_revision"
          icon="pi pi-check-circle"
          :class="deployedConfigTextColorClass"
          :style="{ 'background-color': '#' + deployment.config_revision.color }"
        >
          {{ deployment.config_revision.name }} current revision
        </Tag>
        <Tag
          v-else
          icon="pi pi-book"
          :class="deployedConfigTextColorClass"
          :style="{ 'background-color': '#' + deployment.config_revision.color }"

        >
          {{ deployment.config_revision.name }} revision id: {{ deployment.config_revision.id }}
        </Tag>
      </span>
      <span class="text-xs">
        Deployed by: {{ deployment.user.name }}<br/>
        {{ dayjs(deployment.inserted_at).format('L LT') }}
      </span>
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

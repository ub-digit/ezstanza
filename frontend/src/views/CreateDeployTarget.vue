<script>
import { ref } from 'vue'
import DeployTargetForm from '@/components/DeployTargetForm.vue'
import useOnSubmit from '@/components/UseOnEntityFormSubmit.js'

export default {
  setup() {
    const deployTarget = ref({})

    const onSubmit = useOnSubmit('deploy_target', 'deploy_targets', 'create')

    return {
      deployTarget,
      onSubmit
    }
  },
  components: {
    DeployTargetForm
  }
}
</script>
<template>
  <DeployTargetForm :deployTarget="deployTarget" @submit="onSubmit"/>
</template>

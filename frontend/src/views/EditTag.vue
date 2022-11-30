<script>
import { watch, ref, inject } from 'vue'
import { useRoute } from 'vue-router'
import useOnSubmit from '@/components/UseOnEntityFormSubmit.js'
import TagForm from '@/components/TagForm.vue'

export default {
  setup() {
    const route = useRoute()
    const tag = ref()
    const onSubmit = useOnSubmit('tag', 'tags', 'update')
    const api = inject('api')

    // Replace with watchEffect?
    watch(
      () => route.params.id,
      async newId => {
        // Triggered when leaving route, WTF!?!?
        if (typeof newId !== 'undefined') {
          //TODO: error handling
          const result = await api.tags.fetch(newId)
          tag.value = result.data
        }
      },
      { immediate: true }
    )

    return {
      tag,
      onSubmit
    }
  },
  components: {
    TagForm
  }
}
</script>
<template>
  <TagForm v-if="tag" :tag="tag" @submit="onSubmit"/>
</template>

<script>
import { ref } from 'vue'
import TagForm from '@/components/TagForm.vue'
import useOnSubmit from '@/components/UseOnEntityFormSubmit.js'

export default {
  setup() {
    const tag = ref({})
    const onSubmit = useOnSubmit('tags', 'tag', 'create')

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
  <TagForm :tag="tag" @submit="onSubmit"/>
</template>

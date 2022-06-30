<script>
import { useForm } from 'vee-validate'
import {EditorView, gutter, GutterMarker} from "@codemirror/view"
import {StateField, StateEffect, RangeSet} from "@codemirror/state"
import VCodemirrorField from '@/components/VCodemirrorField.vue'
import VTextField from '@/components/VTextField.vue'
import { isRef, unref, toRaw } from 'vue'

export default {
  emits: ['submit'],
  props: {
    stanza: {
      type: Object,
      required: true
    },
  },
  setup({ stanza }, { emit }) {

    const invalidDirectiveMarker = new class extends GutterMarker {
      toDOM() { return document.createTextNode("ø") }
    }

    const invalidDirectiveEffect = StateEffect.define({
      map: (val, mapping) => ({pos: mapping.mapPos(val.pos), on: val.on})
    })

    const invalidDirectiveState = StateField.define({
      create() { return RangeSet.empty },
      update(set, transaction) {
        set = set.map(transaction.changes)
        for (let e of transaction.effects) {
          if (e.is(invalidDirectiveEffect)) {
            if (e.value.on) {
              set = set.update({add: [invalidDirectiveMarker.range(e.value.pos)]})
            }
            else {
              set = set.update({filter: (from) => from != e.value.pos })
            }
          }
        }
        return set
      }
    })

    const debouncedChange = (function() {
      let timeout = null
      return function (value, viewUpdate) {
        if (viewUpdate.docChanged) {
          clearTimeout(timeout)
          timeout = setTimeout(() => {
            const {from: fromPos, to: toPos} = viewUpdate.view.viewport
            let stateEffects = []
            for (let pos = fromPos; pos <= toPos; pos++) {
              stateEffects.push(invalidDirectiveEffect.of({pos, on: !Boolean(pos % 3)}))
            }
            viewUpdate.view.dispatch({
              effects: stateEffects
            })
          }, 500)
        }
      }
    })()

    const invalidLineGutter = [
      invalidDirectiveState,
      gutter({
        markers: v => v.state.field(invalidDirectiveState),
        initialSpacer: () => invalidDirectiveMarker
      })
    ]

    const stanzaValues = toRaw(stanza)
    const { handleSubmit, isSubmitting, values, errors } = useForm({
      //validationSchema: schema,
      initialValues: {
        ...stanzaValues
      }
    })

    const onSubmit = handleSubmit((values, context) => {
      emit('submit', values, context)
    })

    return {
      debouncedChange,
      invalidLineGutter,
      onSubmit,
      isSubmitting,
      values,
      errors
    }
  },
  components: {
    VCodemirrorField,
    VTextField
  }
}
</script>
<template>
  <form  @submit="onSubmit">
    <label for="name" class="block text-900 font-medium mb-2">Name</label>
    <VTextField id="name" name="name"/>

    <label for="body" class="block text-900 font-medium mb-2">Stanza</label>
    <VCodemirrorField id="body" name="body" :extensions="invalidLineGutter" @change="debouncedChange"/>

    <Button type="submit" :disabled="isSubmitting" label="Save"></Button>
  </form>
</template>


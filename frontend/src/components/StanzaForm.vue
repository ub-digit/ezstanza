<script>
import {useForm} from 'vee-validate'
import {EditorView, gutter, GutterMarker} from "@codemirror/view"
import {StateField, StateEffect, RangeSet} from "@codemirror/state"
import VCodemirrorField from '@/components/VCodemirrorField.vue'
import VTextField from '@/components/VTextField.vue'
import {toRaw} from 'vue'

import {syntaxTree, Language, LanguageSupport} from '@codemirror/language'
import {linter, lintGutter} from '@codemirror/lint'

/*
import {parser} from '../lezer/dist/index.es.js'
import {styleTags, tags as t} from "@lezer/highlight"
import {LRLanguage} from "@codemirror/language"
import {javascript, esLint} from "@codemirror/lang-javascript"
import Linter from "eslint4b-prebuilt"
*/

export default {
  emits: ['submit'],
  props: {
    stanza: {
      type: Object,
      required: true
    },
  },
  setup({ stanza }, { emit }) {

    /*
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
              set = set.update({filter: (from) => from != e.value.pos})
              set = set.update({add: [invalidDirectiveMarker.range(e.value.pos)]})
            }
            else {
              let filter_func = function(from, to, value) {
                return from != e.value.pos
              }
              set = set.update({filter: filter_func})
              set = set.update({filter: (from) => from != e.value.pos})
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
            console.log('doc changed')
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
     */

    const extensions = []
    const ezProxyLinter = linter(view => {
      console.log('linter running, doc:')
      console.log(view.state.doc)
      let diagnostics = []
      diagnostics.push({
        from: 1,
        to: 5,
        serverity: "error",
        message: "Invalid directive",
        actions: [{
          name: "Remove",
          apply(view, from, to) { view.dispatch({changes: {from, to}}) }
        }]
      })
      return diagnostics
    }, {
      delay: 500,
      markerFilter: diagnostics => {
        console.log('Markerfilter running')
        console.dir(diagnostics)
        return diagnostics
      },
      tooltipFilter: diagnostics => {
        console.log('tooltipFilter running')
        return diagnostics
      }
    })

    extensions.push(lintGutter({
      hoverTime: 2000
    }))

    //extensions.push(ezProxyLinter)
    /*

    extensions.push(linter(esLint(new Linter())))
    extensions.push(javascript())

    let stanzaParser = parser.configure({
      props: [
        styleTags({
          Directive: t.variableName,
          Comment: t.lineComment
        })
      ]
    })

    const stanzaLanguage = LRLanguage.define({
      parser: stanzaParser
    })
    */

    //extensions.push(new LanguageSupport(stanzaLanguage))

    const stanzaValues = toRaw(stanza)
    const {handleSubmit, isSubmitting, values, errors} = useForm({
      //validationSchema: schema,
      initialValues: {
        ...stanzaValues
      }
    })

    const onSubmit = handleSubmit((values, context) => {
      emit('submit', values, context)
    })

    return {
      //debouncedChange,
      //invalidLineGutter,
      extensions,
      onSubmit,
      isSubmitting,
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
    <!-- <VCodemirrorField id="body" name="body" :extensions="invalidLineGutter" @change="debouncedChange"/> -->
    <VCodemirrorField id="body" name="body" :extensions="extensions"/>

    <Button type="submit" :disabled="isSubmitting" label="Save"></Button>
  </form>
</template>

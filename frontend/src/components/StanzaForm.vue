<script>
import {useForm} from 'vee-validate'
import {ref, toRef, unref, toRaw, inject, computed, watch} from 'vue'
import {EditorView, gutter, GutterMarker} from "@codemirror/view"
import {StateField, StateEffect, RangeSet} from "@codemirror/state"

import {syntaxTree, Language, LanguageSupport} from '@codemirror/language'
import {linter, lintGutter} from '@codemirror/lint'

import VCodemirrorField from '@/components/VCodemirrorField.vue'
import VTextField from '@/components/VTextField.vue'
import Checkbox from 'primevue/checkbox'

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
  setup( { stanza }, { emit }) {

    //const stanza = toRef(props, 'stanza')

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
    const {handleSubmit, isSubmitting, setFieldValue, useFieldModel, errors} = useForm({
      //validationSchema: schema,
      initialValues: {
        ...stanzaValues,
        include_in_configs: [],
        publish_in_configs: []
      }
    })

    const onSubmit = handleSubmit((values, context) => {
      // Hack, better way to handle this?
      values.publish_in_configs = values.publish_in_configs.filter(
        publishInConfig => values.include_in_configs.some(c => c.id === publishInConfig.id)
      )
      emit('submit', values, context)
    })

    const api = inject('api')
    const configOptions = ref([])

    //setFieldValue('include_in_configs', [])
    //setFieldValue('publish_in_configs', [])
    // Not used?
    const stanzaFormBody = useFieldModel('body')

    const includeInConfigs = useFieldModel('include_in_configs')
    const publishInConfigs = useFieldModel('publish_in_configs')

    const publishInConfigOptions = computed(() => {
      // Use includeInConfigs order
      return configOptions.value.reduce((options, configOption) => {
        let option = includeInConfigs.value.find(c => c.id === configOption.id)
        if (option) {
          options.push(option)
        }
        return options
      }, [])
    })

    let currentConfigsById = Object.fromEntries(
      stanzaValues.current_configs.map(config => [config.id, config])
    )

    api.configs.list().then(result => {
      configOptions.value = result.data.map(
        config => {
          return {
            name: config.name,
            id: config.id,
            has_stanza_revision: config.id in currentConfigsById,
            has_current_stanza_revision: config.id in currentConfigsById && currentConfigsById[config.id].has_current_stanza_revision
          }
        }
      )
      // Set initial config values
      includeInConfigs.value = configOptions.value.filter(
        configOption => configOption.has_stanza_revision
      )
      publishInConfigs.value = configOptions.value.filter(
        configOption => configOption.has_current_stanza_revision
      )
    })

    const forcePublishInConfigs = computed(
      () => includeInConfigs.value.filter(config => !config.has_stanza_revision)
    )

    watch(forcePublishInConfigs, () => {
      forcePublishInConfigs.value.forEach((forcePublishConfig) => {
        if (!publishInConfigs.value.find(config => config.id === forcePublishConfig.id)) {
          publishInConfigs.value.push(forcePublishConfig)
        }
      })
    })

    const stanzaRevisionChanged = computed(() => stanza.body !== stanzaFormBody.value)
    watch(stanzaRevisionChanged, () => {
      // Changed back to unchaged current revision state
      if(!stanzaRevisionChanged.value) {
        publishInConfigs.value = configOptions.value.filter(
          configOption => configOption.has_current_stanza_revision ||
            forcePublishInConfigs.value.find(c => c.id === configOption.id)
        )
      }
    })

    return {
      //debouncedChange,
      //invalidLineGutter,
      publishInConfigs,
      includeInConfigs,
      publishInConfigOptions,
      configOptions,
      extensions,
      onSubmit,
      isSubmitting,
      stanzaRevisionChanged,
      errors //remove?
    }
  },
  components: {
    VCodemirrorField,
    VTextField,
    Checkbox
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

    <template v-if="publishInConfigOptions.length">
      <h5>Publish current revision in</h5>
      <div class="formgroup-inline">
        <div v-for="config in publishInConfigOptions" :key="config.id" class="field-checkbox">
          <Checkbox :inputId="config.id" name="config" :value="config" v-model="publishInConfigs" :disabled="!stanzaRevisionChanged && config.has_current_stanza_revision || !config.has_stanza_revision"/>
          <label :for="config.id">{{ config.name }}</label>
        </div>
      </div>
    </template>

    <h5>Include stanza in</h5>
      <div v-for="config in configOptions" :key="config.id" class="field-checkbox">
        <Checkbox :inputId="config.id" name="config" :value="config" v-model="includeInConfigs"/>
        <label :for="config.id">{{ config.name }}</label>
      </div>
    <Button type="submit" :disabled="isSubmitting" label="Save"></Button>
  </form>
</template>

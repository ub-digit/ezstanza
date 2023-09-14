<script>
import {useForm} from 'vee-validate'
import {ref, toRef, unref, toRaw, inject, computed, watch} from 'vue'
import {EditorView, gutter, GutterMarker} from "@codemirror/view"
import {StateField, StateEffect, RangeSet} from "@codemirror/state"

import {syntaxTree, Language, LanguageSupport} from '@codemirror/language'
import {linter, lintGutter} from '@codemirror/lint'

import VCodemirrorField from '@/components/VCodemirrorField.vue'
import VTextField from '@/components/VTextField.vue'
import VTextareaField from '@/components/VTextareaField.vue'
import VAutoCompleteField from '@/components/VAutoCompleteField.vue'
import Checkbox from 'primevue/checkbox'
import Fieldset from 'primevue/fieldset'
//import StanzaCurrentConfigChip from '@/components/StanzaCurrentConfigChip.vue' //@FIXME: Rename, without Chip?

import StanzaCurrentDeployment from '@/components/StanzaCurrentDeployment.vue'

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
    const {handleSubmit, isSubmitting, setFieldValue, useFieldModel} = useForm({
      //validationSchema: schema,
      initialValues: {
        ...stanzaValues,
        deploy_to_deploy_targets: []
      }
    })

    const onSubmit = handleSubmit((values, context) => {
      /*
      values.configs = values.include_in_configs.map(includeInConfig => {
        return {
          id: includeInConfig.id,
          publish: values.publish_in_configs.some(publishInConfig => {
            return publishInConfig.id === includeInConfig.id
          })
          }
        })
       */
      values.deploy_to_deploy_targets = values.deploy_to_deploy_targets.map((deploy_target) => {
        return deploy_target.id
      })
      // Better way of handling this, cast model module?
      // Are these bound?
      delete values.current_deployments
      //delete values.publish_in_configs
      //delete values.include_in_configs
      //delete values.current_configs
      delete values.revision_user // Unset here or elsewhere?
      delete values.user // Unset here or elsewhere?
      const options = {
        destination: values.deploy_to_deploy_targets.length ? '/deployments' : null
      }
      emit('submit', values, context, options)
    })

    const api = inject('api')
    const deployTargets = ref([])

    const body = useFieldModel('body')
    const logMessage = useFieldModel('log_message')

    const stanzaRevisionChanged = computed(() => stanza.body !== body.value)
    watch(stanzaRevisionChanged, () => {
      // Enforce unchanged current revision state
      if(!stanzaRevisionChanged.value) {
        logMessage.value = stanza.log_message
      }
    })

    api.deploy_targets.list().then(result => {
      deployTargets.value = result.data
    })

    const tags = ref([])

    const tagSuggestions = ref([])

    const searchTags = (event) => {
      const query = event.query.trim()
      if (!query) {
        tagSuggestions.value = [...tags.value]
      } else {
        tagSuggestions.value = tags.value.filter((tag) => {
          return tag.name.toLowerCase().startsWith(query.toLowerCase())
        })
        if (!tagSuggestions.value.length) {
          tagSuggestions.value.push({
            name: query
          })
        }
      }
    }

    api.tags.list().then(result => {
      tags.value = result.data.map(tag => {
        return {
          id: tag.id,
          name: tag.name
        }
      })
    })

    const deployToDeployTargets = useFieldModel('deploy_to_deploy_targets')
    const deployTargetOptions = computed(() => {
      return deployTargets.value.filter((deployTarget) => {
        return stanzaRevisionChanged.value || !stanza.current_deployments
          .filter(deployment => deployment.stanza_revision.is_current_revision)
          .map((deployment) => {
            return deployment.deployment.deploy_target.id
          }).includes(deployTarget.id)
      })
    })

    // Is there a less hacky way of achieving this?
    watch(deployTargetOptions, (newOptions) => {
      // Checking length perhaps overzealous micro optimization
      if (deployToDeployTargets.value.length) {
        deployToDeployTargets.value = deployToDeployTargets.value.filter((deployTarget) => {
          return newOptions.map(option => option.id).includes(deployTarget.id)
        })
      }
    })

    // TODO: break out to computed property includeInConfigsRemoved?
    /*
    const stanzaRemovedFromConfig = computed(() => {
      return configOptions.value.some(configOption => {
        return configOption.has_stanza_revision
          && !includeInConfigs.value.some(config => config.id === configOption.id)
      })
    })
    */

    /*
    watch(stanzaRemovedFromConfig, () => {
      if(stanzaRemovedFromConfig.value) {

      }
    })
     */

    return {
      //debouncedChange,
      //invalidLineGutter,
      //publishInConfigs,
      //includeInConfigs,
      //publishInConfigOptions,
      //configOptions,
      deployTargetOptions,
      deployToDeployTargets,
      tags,
      tagSuggestions,
      searchTags,
      extensions,
      onSubmit,
      isSubmitting,
      stanzaRevisionChanged,
      stanza
    }
  },
  components: {
    VCodemirrorField,
    VTextField,
    VTextareaField,
    VAutoCompleteField,
    Checkbox,
    Fieldset,
    StanzaCurrentDeployment
    //StanzaCurrentConfigChip
  }
}
</script>
<template>
  <form @submit="onSubmit">
    <!-- TODO: Lots of repition, add component for label -->
    <label for="name" class="block text-900 font-medium mb-2">Name</label>
    <VTextField id="name" name="name"/>

    <label for="tags" class="block text-900 font-medium mb-2">Tags</label>
    <VAutoCompleteField
      multiple
      :forceSelection="false"
      id="tags"
      name="tags"
      :suggestions="tagSuggestions"
      optionLabel="name"
      @complete="searchTags"
    >
      <template #option="{ option }">
        <template v-if="!option.id">
          <i class="pi pi-plus-circle" style="font-size: 0.9rem"></i>
        </template>
        {{ option.name }}
      </template>
    </VAutoCompleteField>
    <label for="body" class="block text-900 font-medium mb-2">Stanza</label>
    <!-- <VCodemirrorField id="body" name="body" :extensions="invalidLineGutter" @change="debouncedChange"/> -->
    <VCodemirrorField id="body" name="body" :extensions="extensions"/>

    <label for="log-message" class="block text-900 font-medium mb-2">Log</label>
    <VTextareaField
      id="log-message"
      name="log_message"
      rows="2"
      cols="50"
      helpText="Provide a log message describing the current change"
      :disabled="!stanzaRevisionChanged"
    />

    <h5 class="mb-2">Deployments</h5>
    <div class="mb-2 flex flex-column align-items-start gap-2">
      <StanzaCurrentDeployment
        v-for="deployment in stanza.current_deployments"
        :deployment="deployment.deployment"
        :stanzaRevision="deployment.stanza_revision"
      />
    </div>

    <template v-if="deployTargetOptions.length">
      <h5 class="mb-2">Deploy to</h5>
      <div v-for="deployTarget in deployTargetOptions" :key="deployTarget.id" class="field-checkbox">
        <Checkbox :inputId="`deploy-target-${deployTarget.id}`" name="deployTarget" :value="deployTarget" v-model="deployToDeployTargets"/>
        <label :for="`deploy-target-${deployTarget.id}`">{{ deployTarget.name }}</label>
      </div>
    </template>

    <!--
    <div class="flex flex-column align-items-start gap-2">
    </div>

    <div v-for="config in configOptions" :key="config.id" class="field-checkbox">
      <Checkbox :inputId="config.id" name="config" :value="config" v-model="includeInConfigs"/>
      <label :for="config.id">{{ config.name }}</label>
    </div>

    <template v-if="publishInConfigOptions.length">
      <h5 class="mb-2">Publish current revision in</h5>
      <div v-for="config in publishInConfigOptions" :key="config.id" class="field-checkbox">
        <Checkbox
          :inputId="config.id"
          name="config"
          :value="config"
          v-model="publishInConfigs"
          :disabled="!stanzaRevisionChanged && config.has_current_stanza_revision || !config.has_stanza_revision"
        />
        <label :for="config.id">{{ config.name }}</label>
      </div>
    </template>
    <template v-if="publishInConfigs.length">
      <Fieldset legend="Deployment" class="mb-3">
        <template v-for="config in publishInConfigOptions" :key="config.id" class="field-checkbox">
          <h4>{{ config.name }}</h4>
            <h5 class="mb-2">Deploy to</h5>
        </template>
      </Fieldset>
    </template>
    -->

    <Button class="mt-4" type="submit" :disabled="isSubmitting" label="Save"></Button>
  </form>
</template>

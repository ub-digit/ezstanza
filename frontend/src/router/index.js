import { createRouter, createWebHistory } from 'vue-router'
import Login from '../views/Login.vue'
import Home from '../views/Home.vue'

import Stanza from '../views/Stanza.vue'
import EditStanza from '../views/EditStanza.vue'
import EditStanzaStanzaRevisions from '../views/EditStanzaStanzaRevisions.vue'
import CreateStanza from '../views/CreateStanza.vue'
import ListStanzas from '../views/ListStanzas.vue'

import ListDeployments from '../views/ListDeployments.vue'

import EditDeployTarget from '../views/EditDeployTarget.vue'
import CreateDeployTarget from '../views/CreateDeployTarget.vue'
import ListDeployTargets from '../views/ListDeployTargets.vue'

import EditTag from '../views/EditTag.vue'
import CreateTag from '../views/CreateTag.vue'
import ListTags from '../views/ListTags.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'Home',
      component: Home,
      meta: { auth: true }
    }, {
      path: '/login',
      name: 'Login',
      component: Login,
      meta: { auth: false }
    }, {
      path: '/stanzas',
      name: 'ListStanzas',
      component: ListStanzas,
      meta: { auth: true }
    }, {
      path: '/stanzas/new',
      name: 'CreateStanza',
      component: CreateStanza,
      meta: { auth: true }
    }, {
      path: '/stanzas/:id(\\d+)',
      name: 'Stanza',
      component: Stanza,
      meta: { auth: true },
      children: [
        {
          path: '',
          name: 'EditStanza',
          component: EditStanza
        }, {
          path: 'revisions',
          name: 'EditStanzaStanzaRevisions',
          component: EditStanzaStanzaRevisions
        }
      ]
    }, {
      path: '/deployments',
      name: 'ListDeployments',
      component: ListDeployments,
      meta: { auth: true }
    }, {
      path: '/deploy_targets',
      name: 'ListDeployTargets',
      component: ListDeployTargets,
      meta: { auth: true }
    }, {
      path: '/deploy_targets/new',
      name: 'CreateDeployTarget',
      component: CreateDeployTarget,
      meta: { auth: true }
    }, {
      path: '/deploy_targets/:id(\\d+)',
      name: 'EditDeployTarget',
      component: EditDeployTarget,
      meta: { auth: true }
    }, {
      path: '/tags',
      name: 'ListTags',
      component: ListTags,
      meta: { auth: true }
    }, {
      path: '/tags/new',
      name: 'CreateTag',
      component: CreateTag,
      meta: { auth: true }
    }, {
      path: '/tags/:id(\\d+)',
      name: 'EditTag',
      component: EditTag,
      meta: { auth: true }
    }
  ]
})

export default (app) => {
  app.router = router
  app.use(router)
}

import { inject, ref, toRef, toRaw, computed, reactive } from 'vue'
import { FilterMatchMode } from 'primevue/api'

// TODO: Check if pageSize need to be reactive
// TODO: return prop with bindlable attributes, defaultSortField, pageSize etc?
export default function useUserColumn({ revisioned, filters }) {
  const api = inject('api')
  const userOptions = ref([])
  api.users.list().then(result => {
    userOptions.value = result.data.map(
      user => {
        return {
          name: user.name,
          id: user.id
        }
      }
    )
  })

  // TODO: revisioned not reactive here?
  const userField = computed(() => {
    return revisioned ? 'revision_user.name' : 'user.name';
  })
  const userFilterField = computed(() => {
    return revisioned ? 'revision_user_ids' : 'user_ids';
  })
  const userSortField = computed(() => {
    return revisioned ? 'revision_user_name' : 'user_name';
  })

  //TODO: Breaking reactivity here, replace with watcher?
  Object.assign(filters.value, {
    [toRaw(userFilterField.value)]: {
      matchMode: FilterMatchMode.EQUALS,
      value: null
    }
  })

  //TODO: handle lazy, filter on user name instead of id?
  return {
    userColumnAttributes: reactive({ // Hack but works
      field: userField,
      filterField: userFilterField,
      sortField: userSortField,
      sortable: true,
      showFilterMenu: false
    }),
    userMultiSelectAttributes: reactive({
      options: userOptions,
      optionLabel: 'name',
      optionValue: 'id',
      placeholder: 'Any',
      display: 'chip',
      class: 'p-column-filter'
    }),
  }
}


import { ref, onMounted } from 'vue'
import { FilterMatchMode } from 'primevue/api'

// TODO: Check if pageSize need to be reactive
export default function useDataTable({ pageSize, defaultSortField, defaultSortOrder }) {
  const lazyParams = ref({})

  onMounted(() => {
    // TODO: rename lazyParams
    lazyParams.value.page = 1
    lazyParams.value.size = pageSize
    lazyParams.value.order_by = getOrderBy(defaultSortField, defaultSortOrder)
  })

  const page = (event) => {
    lazyParams.value.size = event.rows
    lazyParams.value.page = event.page + 1
  }

  const filterSuffix = {
    [FilterMatchMode.CONTAINS]: '_like',
    [FilterMatchMode.EQUALS]: ''
  }

  const filter = (event) => {
    for (const [filter, data] of Object.entries(event.filters)) {
      const filter_name = filter + filterSuffix[data.matchMode]
      if (typeof data.value !== 'string' || data.value.length) {
        lazyParams.value[filter_name] = data.value
      }
      else {
        delete lazyParams.value[filter_name]
      }
    }
  }

  const getOrderBy = (sortField, sortOrder) => {
    return sortField + (sortOrder === -1 ? '_desc' : '')
  }

  const sort = (event) => {
    lazyParams.value['order_by'] = getOrderBy(event.sortField, event.sortOrder)
  }

  const dataTableEvents = {
    filter,
    page,
    sort
  }

  return {
    lazyParams,
    dataTableEvents
  }
}


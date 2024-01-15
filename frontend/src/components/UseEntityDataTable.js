import { computed, ref, unref, watch, onMounted, inject, reactive } from 'vue'
import { FilterMatchMode } from 'primevue/api'

// TODO: Check if pageSize need to be reactive
// TODO: return prop with bindlable attributes, defaultSortField, pageSize etc?
export default function useEntityDataTable({
  lazy,
  params,
  entityNamePluralized,
  entityLabelPluralized,
  defaultPageSize,
  defaultSortField,
  defaultSortOrder
}) {
  const lazyParams = ref({}) //TODO: Try replace with reactive

  const api = inject('api')

  const loading = ref(false)
  const sortField = ref(defaultSortField)
  const sortOrder = ref(defaultSortOrder)
  const pageSize = ref(defaultPageSize)

  // TODO: Not quite sure why using onMounted here
  onMounted(() => {
    // TODO: rename lazyParams
    // Need to put these in watcher?
    lazyParams.value.page = 1
    lazyParams.value.size = defaultPageSize
    lazyParams.value.order_by = getOrderBy(defaultSortField, defaultSortOrder)
    if (params) {
      watch(params, (newParams) => {
        Object.entries(newParams).forEach(([param, value]) => {
          lazyParams.value[param] = value
        })
      }, { immediate: true })
    }
  })

  const page = (event) => {
    lazyParams.value.size = event.rows
    lazyParams.value.page = event.page + 1
  }

  const filterSuffix = {
    [FilterMatchMode.CONTAINS]: '_like',
    [FilterMatchMode.NOT_EQUALS]: '_not_equals',
    [FilterMatchMode.EQUALS]: ''
  }

  const filter = (event) => {
    for (const [filter, data] of Object.entries(event.filters)) {
      // Posslibly clear old filter value
      Object.keys(lazyParams.value).forEach(param => {
        if (param.startsWith(filter)) {
          delete lazyParams.value[param]
        }
      })
      if (
        typeof data.value === "number" ||
        typeof data.value === "boolean" ||
        (
          (typeof data.value === "string" || Array.isArray(data.value)) &&
          data.value.length
        )
      ) {
        lazyParams.value[filter + filterSuffix[data.matchMode]] = data.value
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

  const entities = ref([])
  const totalEntities = ref(null)

  const loadEntities = (params) => {
    loading.value = true
    params = Object.assign({}, unref(params)) //TODO: someting iffy with this
    // Load ahead some entities so don't have to refetch
    // on every deletion
    // @todo: better name. ahead, ahead_size?
    if (lazy) {
      params.extra = 5
    }
    // TODO: Error handling/toast
    api[entityNamePluralized].list(params).then(result => {
      entities.value = result.data
      totalEntities.value = 'total' in result? result.total : result.data.length
      loading.value = false
    })
  }

  // TODO: loading???
  const loadEntitiesUnpaginated = async () => {
    // @todo: alternatively { ...lazyParams.value } ?
    let params = Object.assign({}, unref(lazyParams))
    delete params.page
    delete params.size
    let result = await api[entityNamePluralized].list(params)
    return result.data
  }

  const maybeLoadEntities = () => {
    if (
      lazy && //TODO: Maybe don't need this check?
      (lazyParams.value.size * (lazyParams.value.page - 1) + entities.value.length) < totalEntities.value &&
      entities.value.length < lazyParams.value.size
    ) {
      loadEntities(lazyParams)
    }
  }
  if (lazy) {
    watch(
      () => lazyParams,
      newParams => { // Why async?
        loadEntities(newParams)
      },
      { deep: true }
    )
  }
  else {
    loadEntities(lazyParams)
  }

  watch(entities, (newEntities, oldEntities) => {
    // TOOD: This check is actually not necessary
    if (newEntities.length < oldEntities.length) {
      maybeLoadEntities()
    }
  })

  // Hide paginator if all entities are currently displayed
  // TODO: should return from useEntityDataTable?
  const paginator = computed(() => {
    // Feature not a but that page size not reacative
    // since don't want to hide pagination if first
    // visiable even if increasing page size to fit all
    // entities
    return totalEntities.value && totalEntities.value > defaultPageSize
  })

  //TODO: works with reactive, but not plain object, the same does not apply for events, weird
  const dataTableProperties = reactive({
    sortField,
    sortOrder,
    paginator,
    loading,
    totalRecords: totalEntities,
    lazy,
    paginatorTemplate: "FirstPageLink PrevPageLink PageLinks NextPageLink LastPageLink CurrentPageReport RowsPerPageDropdown",
    currentPageReportTemplate: `Showing {first} to {last} of {totalRecords} ${entityLabelPluralized}`
  })

  //TODO: Don't return lazyParams, probably never needed?
  return {
    entities,
    totalEntities,
    loadEntitiesUnpaginated,
    lazyParams,
    pageSize, //TODO: Or rows??
    dataTableEvents,
    dataTableProperties
  }
}


export default function useFormSchema(namespace, schema) {

  const schemaEntries = Object.entries(schema)

  const initialValues = Object.fromEntries(
    schemaEntries.map(([fieldName, opts]) => {
      return [`${namespace}.${fieldName}`, opts.default_value]
    })
  )

  const validateRequired = (value) => {
    if (!value) {
      return 'is required' //TODO: translate
    }
    return true
  }

  //TODO: TODO: decimal/float fields must set :minFractionDigits

  const componentsMap = {
    text: "VTextField",
    number: "VNumberField"
    //TODO: 
    /*
    textarea: "VTextAreaField"
    checkbox: "VCheckBoxField",
    select: "VDropdownField"
    */
  }
  const componentOptionsMap = {
    min_fraction_digits: "minFractionDigits"
  }
  //TODO: Error handling!?
  const fieldsSchema = schemaEntries.map(([fieldName, opts]) => {
    let field = {
      ...opts,
      name: `${namespace}.${fieldName}`,
      component: {
        is: componentsMap[opts.component.is],
        options: Object.fromEntries(
          Object.entries(opts.component.options).map(
            ([ option, value ]) => {
              return [ componentOptionsMap[option], value ]
            }
          )
        )
      }
    }
    if (opts.required) {
      field.component.options['rules'] = { required: true } // validateRequired
    }
    return field
  })

  const formSchema = {
    rules: {}, //TODO, probably should use rule per field
    fieldsSchema: fieldsSchema,
    initialValues: initialValues
  }

  return formSchema
}

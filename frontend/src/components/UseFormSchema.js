export default function useFormSchema(namespace, schema) {

  const initialValues = Object.fromEntries(
    schema.map((field) => {
      return [`${namespace}.${field.name}`, field.default_value]
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
  const fieldsSchema = schema.map((field) => {
    let fieldSchema = {
      ...field,
      name: `${namespace}.${field.name}`,
      component: {
        is: componentsMap[field.component.is],
        options: Object.fromEntries(
          Object.entries(field.component.options).map(
            ([ option, value ]) => {
              return [ componentOptionsMap[option], value ]
            }
          )
        )
      }
    }
    if (field.required) {
      fieldSchema.component.options['rules'] = { required: true } // validateRequired
    }
    return fieldSchema
  })

  const formSchema = {
    rules: {}, //TODO, probably should use rule per field
    fieldsSchema: fieldsSchema,
    initialValues: initialValues
  }

  return formSchema
}

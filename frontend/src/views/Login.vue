<script>
// import InputText from 'primevue/inputtext'
import VTextField from '@/components/VTextField.vue'
import Checkbox from 'primevue/checkbox'
import Button from 'primevue/button'
import { useAuth } from '@websanova/vue-auth/src/v3.js'
import { useForm, Field } from 'vee-validate'
import * as yup from 'yup'

export default {
  setup() {
    const auth = useAuth()
    const schema = yup.object({
      auth: yup.object({
        username: yup.string().required().label('Username or email address'),
        password: yup.string().required().label('Password')
      })
    })

    const { handleSubmit, isSubmitting, errors } = useForm({
      validationSchema: schema,
      initialValues: {
        auth : {
          username: '',
          password: '',
          provider: 'password'
        },
        staySignedIn: false
      }
    })

    const onSubmit = handleSubmit((values, {setErrors}) => {
      auth.login({
        data: values.auth,
        staySignedIn: values.staySignedIn,
        redirect: '/' // can remove?
      })
      .catch((error) => {
        if (typeof error.response.data === 'object' && 'errors' in error.response.data) {
          // TODO: ugly
          let errors = {};
          for (const [field, value] of Object.entries(error.response.data.errors)) {
            errors[`auth.${field}`] = value;
          }
          setErrors(errors)
        }
        else {
          //TODO: toast?
          console.log('error')
          console.dir(res)
        }
      })
    })

    return { onSubmit, isSubmitting, errors };
  },
  components: {
    Field,
    Checkbox,
    Button,
    VTextField
  }
}
</script>
<template>
<div class="align-items-center flex justify-content-center lg:px-8 md:px-6 px-4 py-8">
  <div class="surface-card p-4 shadow-2 border-round w-full lg:w-6">
    <form @submit="onSubmit">
      <label for="username" class="block text-900 font-medium mb-2">Username or email address</label>
      <VTextField id="username" name="auth.username" type="text" class="w-full" />

      <label for="password" class="block text-900 font-medium mb-2">Password</label>
      <VTextField id="password" name="auth.password" type="password" class="w-full" />
      <div class="flex align-items-center justify-content-between mb-6">
        <div class="flex align-items-center">
          <Field v-slot="{ handleChange, value }" name="staySignedIn" :value="false" type="checkbox">
            <Checkbox id="stay-signed-in" :modelValue="value" @update:modelValue="handleChange" :binary="true" class="mr-2"></Checkbox>
            <label for="stay-signed-in">Remember me</label>
          </Field>
        </div>
      </div>
      <Button type="submit" :disabled="isSubmitting" label="Sign In" icon="pi pi-user" class="w-full"></Button>
    </form>
  </div>
</div>
</template>

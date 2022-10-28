import dayjs from 'dayjs'
import localizedFormat from 'dayjs/plugin/localizedFormat';
import 'dayjs/locale/en'
import 'dayjs/locale/sv'

export default (app) => {
  dayjs.extend(localizedFormat)
  dayjs.locale('sv')
  app.provide('dayjs', dayjs)
}

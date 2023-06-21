import { toRaw } from 'vue'
export default function UseTextClassForBackground(color, darkClass, brightClass, threshold = 128) {
    const hexToYIQ = (hexColor) => {
      // Convert hex to RGB
      // Quick and dirty without validation
      const [r, g, b] = hexColor.match(/.{2}/g).map(val => parseInt(val, 16))
      // Convert RGB to YIQ
      return ((r * 299) + (g * 587) + (b * 114)) / 1000
    }
    //Return computed instead?
    return hexToYIQ(toRaw(color)) >= threshold ? darkClass : brightClass
}

Component({
  properties: {
    show: {
      type: Boolean,
      value: false
    },
    quote: {
      type: Object,
      value: {
        text: '',
        source: ''
      }
    }
  },

  methods: {
    onClose() {
      this.triggerEvent('close')
    }
  }
})

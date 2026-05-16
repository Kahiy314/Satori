Component({
  properties: {
    progress: {
      type: Number,
      value: 0
    },
    active: {
      type: Boolean,
      value: true
    },
    totalSeconds: {
      type: Number,
      value: 1500
    }
  },

  data: {
    flameTransition: 'top 1s ease',
    burnedTransition: 'height 1s ease'
  },

  lifetimes: {
    attached() {
      this.updateTransitions()
    }
  },

  observers: {
    totalSeconds() {
      this.updateTransitions()
    }
  },

  methods: {
    updateTransitions() {
      const total = this.data.totalSeconds || 1500
      const duration = Math.max(1, total / 75)
      const transition = `top ${duration}s ease`
      const burnedTransition = `height ${duration}s ease`
      this.setData({ flameTransition: transition, burnedTransition: burnedTransition })
    }
  }
})

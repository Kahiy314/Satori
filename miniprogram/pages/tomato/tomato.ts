Page({
  data: {
    mode: 'focus', // focus: 专注模式, rest: 休息模式
    taskName: '背诵《论语》',
    currentTomato: 2,
    totalTomatoes: 4,
    remainingTime: '16:23',
    progress: 65,
    isPaused: false,
    whiteNoise: '雨声',
    timerRunning: false
  },

  onLoad(options: any) {
    if (options.taskName) {
      this.setData({
        taskName: decodeURIComponent(options.taskName)
      })
    }
    console.log('番茄计时页面加载')
  },

  togglePause() {
    this.setData({
      isPaused: !this.data.isPaused
    })
    
    if (this.data.isPaused) {
      wx.showToast({
        title: '已暂停',
        icon: 'success'
      })
    } else {
      wx.showToast({
        title: '继续计时',
        icon: 'success'
      })
    }
  },

  endSession() {
    wx.showModal({
      title: '确认结束',
      content: this.data.mode === 'focus' ? '确定要结束当前专注吗？' : '确定要跳过休息吗？',
      success: (res) => {
        if (res.confirm) {
          wx.navigateBack()
        }
      }
    })
  },

  toggleWhiteNoise() {
    const noises = ['雨声', '海浪', '篝火', '古琴', '无']
    const currentIndex = noises.indexOf(this.data.whiteNoise)
    const nextIndex = (currentIndex + 1) % noises.length
    
    this.setData({
      whiteNoise: noises[nextIndex]
    })
    
    if (noises[nextIndex] !== '无') {
      wx.showToast({
        title: `白噪音：${noises[nextIndex]}`,
        icon: 'none'
      })
    }
  },

  switchMode() {
    const newMode = this.data.mode === 'focus' ? 'rest' : 'focus'
    this.setData({
      mode: newMode,
      remainingTime: newMode === 'focus' ? '25:00' : '05:00',
      progress: newMode === 'focus' ? 0 : 100
    })
    
    wx.showToast({
      title: newMode === 'focus' ? '开始专注' : '开始休息',
      icon: 'success'
    })
  },

  simulateTimer() {
    if (!this.data.timerRunning) {
      this.setData({ timerRunning: true })
      
      // 模拟计时器（实际项目中应该使用真实的计时器）
      const timer = setInterval(() => {
        if (!this.data.isPaused) {
          const timeParts = this.data.remainingTime.split(':')
          let minutes = parseInt(timeParts[0])
          let seconds = parseInt(timeParts[1])
          
          if (seconds > 0) {
            seconds--
          } else if (minutes > 0) {
            minutes--
            seconds = 59
          } else {
            // 时间到，自动切换模式
            clearInterval(timer)
            this.setData({ timerRunning: false })
            
            if (this.data.mode === 'focus') {
              this.switchMode()
              this.simulateTimer()
            } else {
              wx.showModal({
                title: '休息结束',
                content: '休息时间已到，准备开始下一个番茄钟吗？',
                success: (res) => {
                  if (res.confirm) {
                    this.switchMode()
                    this.simulateTimer()
                  } else {
                    wx.navigateBack()
                  }
                }
              })
            }
            return
          }
          
          const newTime = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
          const totalSeconds = this.data.mode === 'focus' ? 25 * 60 : 5 * 60
          const elapsedSeconds = totalSeconds - (minutes * 60 + seconds)
          const newProgress = Math.round((elapsedSeconds / totalSeconds) * 100)
          
          this.setData({
            remainingTime: newTime,
            progress: newProgress
          })
        }
      }, 1000)
    }
  },

  onShow() {
    // 页面显示时开始计时器
    this.simulateTimer()
  },

  onBack() {
    wx.navigateBack()
  }
})
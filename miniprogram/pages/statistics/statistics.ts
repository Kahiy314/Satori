Page({
  data: {
    statsData: {
      todayFocus: 125,
      todayTasks: 3,
      weekFocus: 480,
      weekTasks: 12,
      totalFocus: 3280,
      totalTasks: 86
    },
    trendData: [] as Array<{ day: string; value: number; xPercent: number; yPercent: number }>,
    linePoints: '',
    dotPositions: [] as Array<{ x: number; y: number }>,
    yAxisLabels: [] as string[],
    aiSummary: {
      content: '本周您在学习《论语》相关任务上投入了最多时间，总计320分钟。建议继续保持国学学习习惯，下周可以尝试增加写作类任务平衡发展...',
      lastUpdate: '2024-01-19 14:30'
    }
  },

  onLoad() {
    this.initChartData()
  },

  initChartData() {
    const rawData = [
      { day: '11/1', value: 60 },
      { day: '11/2', value: 90 },
      { day: '11/3', value: 120 },
      { day: '11/4', value: 85 },
      { day: '11/5', value: 110 },
      { day: '11/6', value: 75 },
      { day: '11/7', value: 100 }
    ]

    const maxValue = Math.max(...rawData.map(item => item.value))
    const roundedMax = Math.ceil(maxValue / 20) * 20

    const yLabels = [0, 1, 2, 3, 4, 5, 6].map(i => {
      const val = Math.round(roundedMax - (roundedMax / 6) * i)
      return val === 0 ? '0' : val
    })

    const trendData = rawData.map((item, index) => {
      const xPercent = (index / (rawData.length - 1)) * 100
      const yPercent = (item.value / roundedMax) * 100
      return {
        ...item,
        xPercent: xPercent,
        yPercent: yPercent
      }
    })

    const linePoints = trendData.map((item, index) => {
      const x = (index / (rawData.length - 1)) * 100
      const y = 100 - item.yPercent
      return `${x},${y}`
    }).join(' ')

    const dotPositions = trendData.map((item, index) => {
      return {
        x: (index / (rawData.length - 1)) * 100,
        y: 100 - item.yPercent
      }
    })

    this.setData({
      trendData,
      linePoints,
      dotPositions,
      yAxisLabels: yLabels
    })
  },

  refreshAI() {
    wx.showToast({
      title: 'AI总结已刷新',
      icon: 'success'
    })
  },

  formatMinutes(minutes: number) {
    const hours = Math.floor(minutes / 60)
    const mins = minutes % 60
    return hours > 0 ? `${hours}小时${mins}分钟` : `${mins}分钟`
  }
})

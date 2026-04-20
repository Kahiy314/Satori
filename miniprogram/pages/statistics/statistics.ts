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
    trendData: [
      { day: '11/1', value: 80 },
      { day: '11/2', value: 95 },
      { day: '11/3', value: 120 },
      { day: '11/4', value: 105 },
      { day: '11/5', value: 90 },
      { day: '11/6', value: 110 },
      { day: '11/7', value: 100 }
    ],
    aiSummary: {
      content: '本周您在学习《论语》相关任务上投入了最多时间，总计320分钟。建议继续保持国学学习习惯，下周可以尝试增加写作类任务平衡发展...',
      lastUpdate: '2024-01-19 14:30'
    }
  },

  onLoad() {
    console.log('统计页面加载')
  },

  refreshAI() {
    wx.showToast({
      title: 'AI总结已刷新',
      icon: 'success'
    })
  },

  getMaxValue() {
    return Math.max(...this.data.trendData.map(item => item.value))
  },

  formatMinutes(minutes: number) {
    const hours = Math.floor(minutes / 60)
    const mins = minutes % 60
    return hours > 0 ? `${hours}小时${mins}分钟` : `${mins}分钟`
  }
})
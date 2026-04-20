Page({
  data: {
    tasks: [
      {
        id: '1',
        name: '背诵《论语》',
        listName: '四书五经',
        priority: 'high',
        tomatoCount: 4,
        completedTomatoes: 2,
        focusMinutes: 25
      },
      {
        id: '2',
        name: '完成数学作业',
        listName: '学习任务',
        priority: 'medium',
        tomatoCount: 2,
        completedTomatoes: 1,
        focusMinutes: 25
      },
      {
        id: '3',
        name: '练习书法',
        listName: '兴趣爱好',
        priority: 'low',
        tomatoCount: 1,
        completedTomatoes: 0,
        focusMinutes: 30
      }
    ],
    showListPanel: false,
    currentFilter: 'all'
  },

  onShow() {
    console.log('任务页面加载')
  },

  toggleListPanel() {
    this.setData({
      showListPanel: !this.data.showListPanel
    })
  },

  startTask(e: any) {
    const taskId = e.currentTarget.dataset.id
    const task = this.data.tasks.find(t => t.id === taskId)
    wx.navigateTo({
      url: `/pages/tomato/tomato?taskId=${taskId}&taskName=${task?.name}`
    })
  },

  createTask() {
    wx.showModal({
      title: '创建任务',
      content: '创建任务功能将在后续版本实现',
      showCancel: false
    })
  }
})
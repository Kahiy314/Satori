Page({
  data: {
    currentYear: 2024,
    currentMonth: 1,
    currentDate: 19,
    calendarDays: [],
    todayTasks: {
      completed: 2,
      total: 3
    },
    checkInStatus: false,
    showQuoteModal: false,
    currentQuote: {
      text: '学而时习之，不亦说乎',
      source: '《论语·学而》'
    }
  },

  onLoad() {
    this.generateCalendar()
  },

  generateCalendar() {
    const days = []
    const firstDay = new Date(this.data.currentYear, this.data.currentMonth - 1, 1).getDay()
    const daysInMonth = new Date(this.data.currentYear, this.data.currentMonth, 0).getDate()
    
    // 填充空白
    for (let i = 0; i < firstDay; i++) {
      days.push({ day: '', status: 'empty' })
    }
    
    // 生成日期
    for (let i = 1; i <= daysInMonth; i++) {
      const status = Math.random() > 0.3 ? 'checked' : 'unchecked'
      days.push({ 
        day: i, 
        status: status,
        isToday: i === this.data.currentDate
      })
    }
    
    this.setData({ calendarDays: days })
  },

  handleCheckIn() {
    if (!this.data.checkInStatus) {
      this.setData({ 
        checkInStatus: true,
        showQuoteModal: true,
        todayTasks: { completed: 3, total: 3 }
      })
      
      // 更新今日打卡状态
      const updatedDays = this.data.calendarDays.map(day => {
        if (day.day === this.data.currentDate) {
          return { ...day, status: 'checked' }
        }
        return day
      })
      this.setData({ calendarDays: updatedDays })
    }
  },

  closeQuoteModal() {
    this.setData({ showQuoteModal: false })
  },

  prevMonth() {
    let newMonth = this.data.currentMonth - 1
    let newYear = this.data.currentYear
    if (newMonth < 1) {
      newMonth = 12
      newYear -= 1
    }
    this.setData({ currentMonth: newMonth, currentYear: newYear })
    this.generateCalendar()
  },

  nextMonth() {
    let newMonth = this.data.currentMonth + 1
    let newYear = this.data.currentYear
    if (newMonth > 12) {
      newMonth = 1
      newYear += 1
    }
    this.setData({ currentMonth: newMonth, currentYear: newYear })
    this.generateCalendar()
  }
})
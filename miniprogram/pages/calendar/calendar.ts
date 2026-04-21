import { storage } from '../../utils/storage'
import { generateCalendar, CalendarDay, formatDateStr } from '../../utils/algorithm'

interface Quote {
  text: string
  source: string
}

let quotesCache: Quote[] = []

Page({
  data: {
    currentYear: 0,
    currentMonth: 0,
    weekDays: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
    calendarDays: [] as CalendarDay[],
    todayTasks: { completed: 0, total: 0 },
    todayProgress: 0,
    isTodayChecked: false,
    canCheckIn: false,
    showQuoteModal: false,
    currentQuote: { text: '', source: '' } as Quote
  },

  onLoad() {
    const now = new Date()
    this.setData({
      currentYear: now.getFullYear(),
      currentMonth: now.getMonth() + 1
    })
    this.loadQuotes()
  },

  onShow() {
    this.generateCalendar()
    this.updateTodayTasks()
  },

  loadQuotes() {
    if (quotesCache.length > 0) return
    wx.request({
      url: `${wx.env.USER_DATA_PATH || ''}/assets/data/quotes.json`.replace(wx.env.USER_DATA_PATH || '', ''),
      success: (res) => {
        quotesCache = (res.data as Quote[]) || []
      },
      fail: () => {
        quotesCache = [
          { text: '学而时习之，不亦说乎', source: '《论语·学而》' },
          { text: '天将降大任于斯人也，必先苦其心志', source: '《孟子·告子下》' },
          { text: '苟日新，日日新，又日新', source: '《大学》' },
          { text: '博学之，审问之，慎思之，明辨之，笃行之', source: '《中庸》' },
          { text: '见贤思齐焉，见不贤而内自省也', source: '《论语·里仁》' }
        ]
      }
    })
  },

  generateCalendar() {
    const { currentYear, currentMonth } = this.data
    const checkIns = storage.getCheckIns()
    const checkInMap = new Map<string, boolean>()
    checkIns.forEach(c => checkInMap.set(c.date, c.completed))

    const days = generateCalendar(currentYear, currentMonth, checkInMap)
    this.setData({ calendarDays: days })
  },

  updateTodayTasks() {
    const today = formatDateStr(new Date())
    const tasks = storage.getTasks()
    const todayTasks = tasks.filter(t => {
      const d = new Date(t.dueDate)
      return formatDateStr(d) === today
    })
    const completed = todayTasks.filter(t => t.status === 'completed').length
    const total = todayTasks.length

    const checkIn = storage.getCheckInByDate(today)
    const isChecked = checkIn?.completed || false
    const canCheckIn = !isChecked

    this.setData({
      todayTasks: { completed, total },
      todayProgress: total > 0 ? Math.round((completed / total) * 100) : 0,
      isTodayChecked: isChecked,
      canCheckIn
    })
  },

  prevMonth() {
    let month = this.data.currentMonth - 1
    let year = this.data.currentYear
    if (month < 1) { month = 12; year-- }
    this.setData({ currentYear: year, currentMonth: month })
    this.generateCalendar()
  },

  nextMonth() {
    let month = this.data.currentMonth + 1
    let year = this.data.currentYear
    if (month > 12) { month = 1; year++ }
    this.setData({ currentYear: year, currentMonth: month })
    this.generateCalendar()
  },

  handleCheckIn() {
    if (this.data.isTodayChecked) return

    const today = formatDateStr(new Date())
    const tasks = storage.getTasks()
    const todayStr = formatDateStr(new Date())

    const todayTasks = tasks.filter(t => formatDateStr(new Date(t.dueDate)) === todayStr)
    const completed = todayTasks.filter(t => t.status === 'completed').length

    storage.updateCheckIn(today, {
      completed: true,
      taskCompletedCount: completed,
      totalTaskCount: todayTasks.length
    })

    // 随机选一句名言
    if (quotesCache.length === 0) {
      quotesCache = [
        { text: '学而时习之，不亦说乎', source: '《论语·学而》' },
        { text: '苟日新，日日新，又日新', source: '《大学》' },
        { text: '博学之，审问之，慎思之，明辨之，笃行之', source: '《中庸》' },
        { text: '见贤思齐焉，见不贤而内自省也', source: '《论语·里仁》' },
        { text: '天将降大任于斯人也', source: '《孟子》' }
      ]
    }
    const quote = quotesCache[Math.floor(Math.random() * quotesCache.length)]

    this.setData({
      isTodayChecked: true,
      canCheckIn: false,
      showQuoteModal: true,
      currentQuote: quote
    })
    this.generateCalendar()

    wx.vibrateShort({ type: 'medium' })
  },

  closeQuoteModal() {
    this.setData({ showQuoteModal: false })
  }
})

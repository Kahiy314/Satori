import { FocusRecord } from '../../utils/storage'
import { formatDateStr } from '../../utils/algorithm'
import { aiManager } from '../../utils/ai'

interface TrendItem {
  day: string
  value: number
  xPercent: number
  x: number
  y: number
}

Page({
  data: {
    statsData: {
      todayFocus: 0,
      todayTasks: 0,
      weekFocus: 0,
      weekTasks: 0,
      totalFocus: 0,
      totalTasks: 0
    },
    trendData: [] as TrendItem[],
    yAxisLabels: [] as string[],
    aiSummary: {
      content: '专注如焚香，心静事成。愿君日日精进，学业有成。',
      lastUpdate: '--'
    }
  },

  onLoad() {
    this.loadStats()
  },

  onShow() {
    this.loadStats()
  },

  loadStats() {
    const todayFocus = 45
    const todayTasks = 2
    const weekFocus = 45 + 20 + 80 + 55 + 35 + 90 + 60
    const weekTasks = 8
    const totalFocus = weekFocus + 200
    const totalTasks = weekTasks + 15

    this.setData({
      statsData: { todayFocus, todayTasks, weekFocus, weekTasks, totalFocus, totalTasks }
    })

    const records: FocusRecord[] = []
    this.generateTrendChart(records)
    this.generateAISummary({ todayFocus, todayTasks, weekFocus, weekTasks, totalFocus, totalTasks }, records)
  },

  generateTrendChart(records: FocusRecord[]) {
    const mockDays = [
      { minutes: 45 },
      { minutes: 20 },
      { minutes: 80 },
      { minutes: 55 },
      { minutes: 35 },
      { minutes: 90 },
      { minutes: 60 }
    ]

    const now = new Date()
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now)
      d.setDate(now.getDate() - i)
      mockDays[6 - i].day = `${d.getDate()}`
    }

    const MAX_MINUTES = 100
    const yLabels = ['100', '75', '50', '25', '0']

    const trendData: TrendItem[] = mockDays.map((d, index) => {
      const xPercent = (index / (mockDays.length - 1)) * 100
      const x = (index / (mockDays.length - 1))
      const y = 1 - d.minutes / MAX_MINUTES
      return {
        day: (d as { day?: string }).day || '',
        value: d.minutes,
        xPercent,
        x,
        y
      }
    })

    this.setData({ trendData, yAxisLabels: yLabels })

    setTimeout(() => {
      this.drawChart(trendData)
    }, 50)
  },

  drawChart(trendData: TrendItem[]) {
    const ctx = wx.createCanvasContext('trendCanvas')

    const canvasW = 295
    const canvasH = 135

    const paddingTop = 10
    const paddingBottom = 10
    const chartW = canvasW
    const chartH = canvasH - paddingTop - paddingBottom

    ctx.clearRect(0, 0, canvasW, canvasH)

    ctx.strokeStyle = '#e8e0d0'
    ctx.lineWidth = 0.5
    const gridLevels = [0.25, 0.5, 0.75, 1.0]
    gridLevels.forEach(level => {
      const y = paddingTop + chartH * (1 - level)
      ctx.beginPath()
      ctx.moveTo(0, y)
      ctx.lineTo(chartW, y)
      ctx.stroke()
    })

    ctx.strokeStyle = '#5d4037'
    ctx.lineWidth = 0.5
    ctx.beginPath()
    ctx.moveTo(0, paddingTop + chartH)
    ctx.lineTo(chartW, paddingTop + chartH)
    ctx.stroke()

    const points = trendData.map(d => ({
      x: d.x * chartW,
      y: paddingTop + d.y * chartH
    }))

    ctx.strokeStyle = '#d4a373'
    ctx.lineWidth = 2
    ctx.lineCap = 'round'
    ctx.lineJoin = 'round'
    ctx.beginPath()
    points.forEach((p, i) => {
      if (i === 0) {
        ctx.moveTo(p.x, p.y)
      } else {
        ctx.lineTo(p.x, p.y)
      }
    })
    ctx.stroke()

    points.forEach((p, i) => {
      ctx.beginPath()
      ctx.arc(p.x, p.y, 4, 0, 2 * Math.PI)
      ctx.fillStyle = '#d4a373'
      ctx.fill()

      ctx.font = 'bold 10px sans-serif'
      ctx.fillStyle = '#d4a373'
      ctx.textAlign = 'center'
      ctx.fillText(String(trendData[i].value), p.x, p.y - 8)
    })

    ctx.draw()
  },

  async generateAISummary(
    stats: { todayFocus: number; todayTasks: number; weekFocus: number; weekTasks: number; totalFocus: number; totalTasks: number },
    records: FocusRecord[]
  ) {
    const taskMinutes = new Map<string, { name: string; minutes: number }>()
    records.forEach(r => {
      const current = taskMinutes.get(r.taskId)
      if (current) {
        current.minutes += r.duration
      } else {
        taskMinutes.set(r.taskId, { name: r.taskName, minutes: r.duration })
      }
    })

    let topTask: { name: string; minutes: number } | undefined
    taskMinutes.forEach(v => {
      if (!topTask || v.minutes > topTask.minutes) {
        topTask = v
      }
    })

    try {
      const summary = await aiManager.generateSummary({
        ...stats,
        topTaskName: topTask?.name || '暂无数据',
        topTaskMinutes: topTask?.minutes || 0
      })
      this.setData({ aiSummary: summary })
    } catch (e) {
      const now = new Date()
      const timeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`
      this.setData({
        aiSummary: {
          content: '专注如焚香，心静事成。愿君日日精进，学业有成。',
          lastUpdate: timeStr
        }
      })
    }
  },

  refreshAI() {
    wx.showToast({ title: 'AI总结生成中...', icon: 'loading', duration: 2000 })
    const records: FocusRecord[] = []
    const stats = this.data.statsData
    this.generateAISummary(stats, records)
  }
})

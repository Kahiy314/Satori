import { FocusRecord, storage } from '../../utils/storage'
import {
  aggregateFocusRecords,
  buildSevenDayFocusTrend,
  getFocusTrendScaleMax,
  getFocusTrendYAxisLabels
} from '../../utils/algorithm'
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
    hasFocusRecords: false,
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
    const records = storage.getFocusRecords()
    const statsData = aggregateFocusRecords(records)

    this.setData({
      statsData,
      hasFocusRecords: records.length > 0
    })

    this.generateTrendChart(records)
    this.generateAISummary(statsData, records)
  },

  generateTrendChart(records: FocusRecord[]) {
    const dailyTrend = buildSevenDayFocusTrend(records)
    const maxMinutes = Math.max(...dailyTrend.map(item => item.minutes))
    const scaleMax = getFocusTrendScaleMax(maxMinutes)
    const yLabels = getFocusTrendYAxisLabels(maxMinutes)

    const trendData: TrendItem[] = dailyTrend.map((item, index) => {
      const xPercent = (index / (dailyTrend.length - 1)) * 100
      const x = (index / (dailyTrend.length - 1))
      const y = 1 - item.minutes / scaleMax
      return {
        day: item.day,
        value: item.minutes,
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
      ctx.setTextAlign('center')
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
    const records = storage.getFocusRecords()
    const stats = aggregateFocusRecords(records)
    this.generateAISummary(stats, records)
  }
})

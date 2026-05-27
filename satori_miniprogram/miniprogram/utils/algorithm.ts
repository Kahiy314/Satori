// ========== 算法实现 ==========
// 链表、队列、栈、哈希表、日历生成、统计图遍历

import { Task, FocusRecord } from './storage'

// ========== 任务链表 ==========
export class TaskNode {
  data: Task
  next: TaskNode | null = null
  constructor(task: Task) {
    this.data = task
  }
}

export class TaskLinkedList {
  head: TaskNode | null = null

  // 头插法
  insertAtHead(task: Task): void {
    const node = new TaskNode(task)
    node.next = this.head
    this.head = node
  }

  // 按时间顺序插入（保持有序）
  insertByTime(task: Task): void {
    const node = new TaskNode(task)
    if (!this.head || task.dueDate <= this.head.data.dueDate) {
      node.next = this.head
      this.head = node
      return
    }
    let current = this.head
    while (current.next && current.next.data.dueDate < task.dueDate) {
      current = current.next
    }
    node.next = current.next
    current.next = node
  }

  // 删除指定 ID
  deleteById(id: string): boolean {
    if (!this.head) return false
    if (this.head.data.id === id) {
      this.head = this.head.next
      return true
    }
    let current = this.head
    while (current.next) {
      if (current.next.data.id === id) {
        current.next = current.next.next
        return true
      }
      current = current.next
    }
    return false
  }

  // 按优先级冒泡排序
  sortByPriority(): void {
    if (!this.head) return
    const priorityOrder: Record<string, number> = { high: 3, medium: 2, low: 1, none: 0 }

    let swapped = true
    let dummy = new TaskNode({} as Task)
    dummy.next = this.head

    while (swapped) {
      swapped = false
      let current: TaskNode | null = dummy
      while (current?.next?.next) {
        if (priorityOrder[current.next.data.priority] > priorityOrder[current.next.next.data.priority]) {
          const next1: TaskNode = current.next
          const next2 = next1.next as TaskNode
          next1.next = next2.next
          current.next = next2
          next2.next = next1
          swapped = true
        }
        current = current.next
      }
    }
    this.head = dummy.next
  }

  // 搜索（返回数组）
  toArray(): Task[] {
    const result: Task[] = []
    let current = this.head
    while (current) {
      result.push(current.data)
      current = current.next
    }
    return result
  }

  // 从数组构建链表
  static fromArray(tasks: Task[]): TaskLinkedList {
    const list = new TaskLinkedList()
    for (let i = tasks.length - 1; i >= 0; i--) {
      list.insertAtHead(tasks[i])
    }
    return list
  }

  // KMP 模式匹配（搜索任务名称）
  searchByName(pattern: string): Task[] {
    const arr = this.toArray()
    const lps = this.computeLPS(pattern)
    const result: Task[] = []
    let j = 0

    for (const task of arr) {
      while (j > 0 && pattern[j] !== task.name[j]) {
        j = lps[j - 1]
      }
      if (pattern[j] === task.name[j]) j++
      if (j === pattern.length) {
        result.push(task)
        j = lps[j - 1]
      }
    }
    return result
  }

  private computeLPS(pattern: string): number[] {
    const lps = new Array(pattern.length).fill(0)
    let len = 0, i = 1
    while (i < pattern.length) {
      if (pattern[i] === pattern[len]) {
        lps[i++] = ++len
      } else if (len > 0) {
        len = lps[len - 1]
      } else {
        lps[i++] = 0
      }
    }
    return lps
  }
}

// ========== 专注周期队列 ==========
export type PomodoroState = 'work' | 'rest' | 'complete'

export class PomodoroQueue {
  private workMinutes: number
  private restMinutes: number
  private currentCycle: number = 1
  private totalCycles: number
  private state: PomodoroState = 'work'

  constructor(workMinutes: number = 25, restMinutes: number = 5, totalCycles: number = 4) {
    this.workMinutes = workMinutes
    this.restMinutes = restMinutes
    this.totalCycles = totalCycles
  }

  getCurrentState(): PomodoroState {
    return this.state
  }

  getCurrentCycle(): number {
    return this.currentCycle
  }

  getTotalCycles(): number {
    return this.totalCycles
  }

  getWorkMinutes(): number {
    return this.workMinutes
  }

  getRestMinutes(): number {
    return this.restMinutes
  }

  // 切换到下一个状态
  next(): PomodoroState {
    if (this.state === 'work') {
      if (this.currentCycle >= this.totalCycles) {
        this.state = 'complete'
      } else {
        this.state = 'rest'
      }
    } else if (this.state === 'rest') {
      this.currentCycle++
      this.state = 'work'
    }
    return this.state
  }

  // 重置
  reset(): void {
    this.currentCycle = 1
    this.state = 'work'
  }

  // 跳过休息
  skipRest(): PomodoroState {
    if (this.state === 'rest') {
      this.currentCycle++
      this.state = 'work'
    }
    return this.state
  }

  // 获取总剩余分钟数（估算）
  getRemainingMinutes(): number {
    if (this.state === 'complete') return 0
    const currentMinutes = this.state === 'work' ? this.workMinutes : this.restMinutes
    const remainingCycles = this.totalCycles - this.currentCycle + (this.state === 'rest' ? 1 : 0)
    return currentMinutes + remainingCycles * (this.workMinutes + this.restMinutes)
  }
}

// ========== 哈希表（任务快速查找） ==========
export class TaskHashMap {
  private buckets: Map<string, Task>[] = []
  private size: number = 100

  constructor(size: number = 100) {
    this.size = size
    for (let i = 0; i < size; i++) {
      this.buckets.push(new Map())
    }
  }

  private hash(id: string): number {
    let hash = 0
    for (let i = 0; i < id.length; i++) {
      hash = ((hash << 5) - hash + id.charCodeAt(i)) | 0
    }
    return Math.abs(hash) % this.size
  }

  set(task: Task): void {
    const index = this.hash(task.id)
    this.buckets[index].set(task.id, task)
  }

  get(id: string): Task | undefined {
    const index = this.hash(id)
    return this.buckets[index].get(id)
  }

  has(id: string): boolean {
    const index = this.hash(id)
    return this.buckets[index].has(id)
  }

  delete(id: string): boolean {
    const index = this.hash(id)
    return this.buckets[index].delete(id)
  }

  // O(1) 批量构建
  buildFromArray(tasks: Task[]): void {
    tasks.forEach(task => this.set(task))
  }

  // 获取所有任务
  getAll(): Task[] {
    const result: Task[] = []
    this.buckets.forEach(bucket => {
      bucket.forEach(task => result.push(task))
    })
    return result
  }
}

// ========== 日历生成算法（DFS/BFS 遍历） ==========
export interface CalendarDay {
  day: number | null
  date: string | null
  status: 'empty' | 'unchecked' | 'checked'
  isToday: boolean
  isCurrentMonth: boolean
}

export function generateCalendar(year: number, month: number, checkInMap?: Map<string, boolean>): CalendarDay[] {
  const days: CalendarDay[] = []
  const today = new Date()
  const todayStr = toDateString(today)

  // 该月第一天是周几（周一=0）
  const firstDay = new Date(year, month - 1, 1)
  let dayOfWeek = firstDay.getDay() - 1
  if (dayOfWeek < 0) dayOfWeek = 6

  // 该月总天数
  const daysInMonth = new Date(year, month, 0).getDate()

  // 上月天数
  const prevMonthDays = new Date(year, month - 1, 0).getDate()

  // 填充上月剩余天数（灰色占位）
  for (let i = dayOfWeek - 1; i >= 0; i--) {
    const d = prevMonthDays - i
    const prevMonth = month === 1 ? 12 : month - 1
    const prevYear = month === 1 ? year - 1 : year
    days.push({
      day: d,
      date: `${prevYear}-${String(prevMonth).padStart(2, '0')}-${String(d).padStart(2, '0')}`,
      status: 'empty',
      isToday: false,
      isCurrentMonth: false
    })
  }

  // 填充当月天数（DFS 遍历模拟）
  function fillMonthDays(start: number, end: number): void {
    if (start > end) return
    for (let d = start; d <= end; d++) {
      const dateStr = `${year}-${String(month).padStart(2, '0')}-${String(d).padStart(2, '0')}`
      const isToday = dateStr === todayStr
      let status: 'unchecked' | 'checked' | 'empty' = 'unchecked'
      if (checkInMap && checkInMap.has(dateStr)) {
        status = checkInMap.get(dateStr) ? 'checked' : 'unchecked'
      }
      days.push({
        day: d,
        date: dateStr,
        status,
        isToday,
        isCurrentMonth: true
      })
    }
  }
  fillMonthDays(1, daysInMonth)

  // 填充下月天数（补齐到 42 格）
  const remaining = 42 - days.length
  for (let d = 1; d <= remaining; d++) {
    const nextMonth = month === 12 ? 1 : month + 1
    const nextYear = month === 12 ? year + 1 : year
    days.push({
      day: d,
      date: `${nextYear}-${String(nextMonth).padStart(2, '0')}-${String(d).padStart(2, '0')}`,
      status: 'empty',
      isToday: false,
      isCurrentMonth: false
    })
  }

  return days
}

function toDateString(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
}

// ========== 专注记录图（邻接表） ==========
export class FocusGraph {
  adjacencyList: Map<string, FocusRecord[]> = new Map()

  addRecord(record: FocusRecord): void {
    if (!this.adjacencyList.has(record.date)) {
      this.adjacencyList.set(record.date, [])
    }
    this.adjacencyList.get(record.date)!.push(record)
  }

  // DFS 遍历获取指定日期范围数据
  getRecordsInRange(startDate: string, endDate: string): FocusRecord[] {
    const result: FocusRecord[] = []
    const dates = Array.from(this.adjacencyList.keys())
      .filter(d => d >= startDate && d <= endDate)
      .sort()

    const visited = new Set<string>()
    for (const date of dates) {
      if (!visited.has(date)) {
        visited.add(date)
        const records = this.adjacencyList.get(date) || []
        result.push(...records)
      }
    }
    return result
  }

  get(date: string): FocusRecord[] {
    return this.adjacencyList.get(date) || []
  }

  // 聚合统计数据
  aggregateStats(records: FocusRecord[]): {
    totalMinutes: number
    taskCount: number
    dailyMinutes: Map<string, number>
  } {
    const dailyMinutes = new Map<string, number>()
    let totalMinutes = 0
    const taskIds = new Set<string>()

    records.forEach(r => {
      totalMinutes += r.duration
      taskIds.add(r.taskId)
      dailyMinutes.set(r.date, (dailyMinutes.get(r.date) || 0) + r.duration)
    })

    return { totalMinutes, taskCount: taskIds.size, dailyMinutes }
  }

  // 构建从存储记录
  buildFromRecords(records: FocusRecord[]): void {
    this.adjacencyList.clear()
    records.forEach(r => this.addRecord(r))
  }
}

// ========== 辅助工具 ==========
export function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).substr(2, 9)
}

export function formatDate(date: Date | number): string {
  const d = typeof date === 'number' ? new Date(date) : date
  return `${d.getMonth() + 1}/${d.getDate()}`
}

export function formatDateStr(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
}

export function getToday(): string {
  return toDateString(new Date())
}

// ========== 专注统计聚合 ==========
export interface FocusStats {
  todayFocus: number
  todayTasks: number
  weekFocus: number
  weekTasks: number
  totalFocus: number
  totalTasks: number
}

export interface FocusTrendDay {
  date: string
  day: string
  minutes: number
}

export function aggregateFocusRecords(records: FocusRecord[], today: Date = new Date()): FocusStats {
  const todayStr = formatDateStr(today)
  const weekStart = getWeekStart(today)
  const weekStartStr = formatDateStr(weekStart)
  const weekEndStr = formatDateStr(addDays(weekStart, 6))

  const todayRecords = records.filter(record => record.date === todayStr)
  const weekRecords = records.filter(record => record.date >= weekStartStr && record.date <= weekEndStr)

  return {
    todayFocus: sumFocusMinutes(todayRecords),
    todayTasks: countUniqueFocusTasks(todayRecords),
    weekFocus: sumFocusMinutes(weekRecords),
    weekTasks: countUniqueFocusTasks(weekRecords),
    totalFocus: sumFocusMinutes(records),
    totalTasks: countUniqueFocusTasks(records)
  }
}

export function buildSevenDayFocusTrend(records: FocusRecord[], today: Date = new Date()): FocusTrendDay[] {
  const minutesByDate = new Map<string, number>()
  records.forEach(record => {
    minutesByDate.set(record.date, (minutesByDate.get(record.date) || 0) + record.duration)
  })

  const endDate = startOfDay(today)
  const trend: FocusTrendDay[] = []
  for (let i = 6; i >= 0; i--) {
    const date = addDays(endDate, -i)
    const dateStr = formatDateStr(date)
    trend.push({
      date: dateStr,
      day: String(date.getDate()),
      minutes: minutesByDate.get(dateStr) || 0
    })
  }
  return trend
}

export function getFocusTrendScaleMax(maxMinutes: number): number {
  const safeMax = Math.max(maxMinutes, 0)
  const step = Math.ceil(Math.max(safeMax, 100) / 4 / 25) * 25
  return step * 4
}

export function getFocusTrendYAxisLabels(maxMinutes: number): string[] {
  const scaleMax = getFocusTrendScaleMax(maxMinutes)
  return [scaleMax, scaleMax * 0.75, scaleMax * 0.5, scaleMax * 0.25, 0]
    .map(value => String(Math.round(value)))
}

function sumFocusMinutes(records: FocusRecord[]): number {
  return records.reduce((sum, record) => sum + record.duration, 0)
}

function countUniqueFocusTasks(records: FocusRecord[]): number {
  const taskIds = new Set<string>()
  records.forEach(record => taskIds.add(record.taskId))
  return taskIds.size
}

function getWeekStart(date: Date): Date {
  const start = startOfDay(date)
  const day = start.getDay()
  const mondayOffset = day === 0 ? -6 : 1 - day
  return addDays(start, mondayOffset)
}

function startOfDay(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate())
}

function addDays(date: Date, days: number): Date {
  const nextDate = new Date(date)
  nextDate.setDate(nextDate.getDate() + days)
  return nextDate
}

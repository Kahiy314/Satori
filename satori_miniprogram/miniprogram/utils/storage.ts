// ========== 统一存储封装 ==========

export const STORAGE_KEYS = {
  TASKS: 'incense_tasks',
  LISTS: 'incense_lists',
  FOCUS_RECORDS: 'incense_focus_records',
  CHECKINS: 'incense_checkins',
  SETTINGS: 'incense_settings'
}

export interface Task {
  id: string
  name: string
  listId: string
  listName: string
  priority: 'none' | 'low' | 'medium' | 'high'
  tomatoCount: number
  completedTomatoes: number
  focusMinutes: number
  status: 'pending' | 'completed'
  dueDate: number
  dueDateStr: string
  createdAt: number
}

export interface TaskList {
  id: string
  name: string
  icon: string
  taskCount: number
}

export interface FocusRecord {
  id: string
  taskId: string
  taskName: string
  duration: number
  date: string
  timestamp: number
}

export interface CheckInRecord {
  date: string
  completed: boolean
  taskCompletedCount: number
  totalTaskCount: number
}

export interface Settings {
  theme: 'light' | 'dark' | 'auto'
  whiteNoise: 'rain' | 'waves' | 'fire' | 'gugin' | 'none'
  restSound: 'guzheng' | 'bowl' | 'birds' | 'none'
  restDuration: number
}

class Storage {
  get<T>(key: string, defaultValue: T): T
  get<T>(key: string): T | undefined
  get<T>(key: string, defaultValue?: T): T | undefined {
    const raw = wx.getStorageSync(key)
    if (raw === '') return defaultValue
    return (raw !== undefined && raw !== '') ? raw : defaultValue
  }

  set<T>(key: string, value: T): void {
    wx.setStorageSync(key, value)
  }

  remove(key: string): void {
    wx.removeStorageSync(key)
  }

  clear(): void {
    wx.clearStorageSync()
  }

  // ========== 任务相关 ==========
  getTasks(): Task[] {
    return this.get<Task[]>(STORAGE_KEYS.TASKS, [])
  }

  setTasks(tasks: Task[]): void {
    this.set(STORAGE_KEYS.TASKS, tasks)
  }

  addTask(task: Task): void {
    const tasks = this.getTasks()
    tasks.unshift(task)
    this.setTasks(tasks)
  }

  updateTask(taskId: string, updates: Partial<Task>): Task | null {
    const tasks = this.getTasks()
    const index = tasks.findIndex(t => t.id === taskId)
    if (index === -1) return null
    tasks[index] = { ...tasks[index], ...updates }
    this.setTasks(tasks)
    return tasks[index]
  }

  deleteTask(taskId: string): boolean {
    const tasks = this.getTasks()
    const index = tasks.findIndex(t => t.id === taskId)
    if (index === -1) return false
    tasks.splice(index, 1)
    this.setTasks(tasks)
    return true
  }

  getTaskById(taskId: string): Task | undefined {
    return this.getTasks().find(t => t.id === taskId)
  }

  // ========== 清单相关 ==========
  getLists(): TaskList[] {
    return this.get<TaskList[]>(STORAGE_KEYS.LISTS, [])
  }

  setLists(lists: TaskList[]): void {
    this.set(STORAGE_KEYS.LISTS, lists)
  }

  addList(list: TaskList): void {
    const lists = this.getLists()
    lists.push(list)
    this.setLists(lists)
  }

  updateList(listId: string, updates: Partial<TaskList>): TaskList | null {
    const lists = this.getLists()
    const index = lists.findIndex(l => l.id === listId)
    if (index === -1) return null
    lists[index] = { ...lists[index], ...updates }
    this.setLists(lists)
    return lists[index]
  }

  deleteList(listId: string): boolean {
    const lists = this.getLists()
    const index = lists.findIndex(l => l.id === listId)
    if (index === -1) return false
    lists.splice(index, 1)
    this.setLists(lists)
    return true
  }

  // ========== 专注记录相关 ==========
  getFocusRecords(): FocusRecord[] {
    return this.get<FocusRecord[]>(STORAGE_KEYS.FOCUS_RECORDS, [])
  }

  addFocusRecord(record: FocusRecord): void {
    const records = this.getFocusRecords()
    records.push(record)
    this.set(STORAGE_KEYS.FOCUS_RECORDS, records)
  }

  saveFocusRecords(records: FocusRecord[]): void {
    this.set(STORAGE_KEYS.FOCUS_RECORDS, records)
  }

  getFocusRecordsByDate(date: string): FocusRecord[] {
    return this.getFocusRecords().filter(r => r.date === date)
  }

  getFocusRecordsInRange(startDate: string, endDate: string): FocusRecord[] {
    return this.getFocusRecords().filter(r => r.date >= startDate && r.date <= endDate)
  }

  // ========== 打卡相关 ==========
  getCheckIns(): CheckInRecord[] {
    return this.get<CheckInRecord[]>(STORAGE_KEYS.CHECKINS, [])
  }

  setCheckIns(records: CheckInRecord[]): void {
    this.set(STORAGE_KEYS.CHECKINS, records)
  }

  updateCheckIn(date: string, updates: Partial<CheckInRecord>): void {
    const records = this.getCheckIns()
    const index = records.findIndex(r => r.date === date)
    if (index !== -1) {
      records[index] = { ...records[index], ...updates }
    } else {
      records.push({ date, completed: false, taskCompletedCount: 0, totalTaskCount: 0, ...updates })
    }
    this.setCheckIns(records)
  }

  getCheckInByDate(date: string): CheckInRecord | undefined {
    return this.getCheckIns().find(r => r.date === date)
  }

  // ========== 设置相关 ==========
  getSettings(): Settings {
    return this.get<Settings>(STORAGE_KEYS.SETTINGS, {
      theme: 'light',
      whiteNoise: 'rain',
      restSound: 'guzheng',
      restDuration: 5
    })
  }

  setSettings(settings: Settings): void {
    this.set(STORAGE_KEYS.SETTINGS, settings)
  }

  updateSettings(updates: Partial<Settings>): void {
    const current = this.getSettings()
    this.setSettings({ ...current, ...updates })
  }

  // ========== 初始化默认数据 ==========
  initDefaultData(): void {
    if (this.getLists().length === 0) {
      this.setLists([
        { id: 'list-1', name: '四书五经', icon: '📘', taskCount: 0 },
        { id: 'list-2', name: '学习任务', icon: '📝', taskCount: 0 },
        { id: 'list-3', name: '兴趣爱好', icon: '🎨', taskCount: 0 }
      ])
    }
  }
}

export const storage = new Storage()

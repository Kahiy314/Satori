interface Task {
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

interface TaskList {
  id: string
  name: string
  icon: string
  taskCount: number
}

interface FormData {
  name: string
  listId: string
  priority: 'none' | 'low' | 'medium' | 'high'
  dueDate: string
  dueDateStr: string
  tomatoCount: number
  focusMinutes: number
}

const STORAGE_KEYS = {
  TASKS: 'incense_tasks',
  LISTS: 'incense_lists'
}

function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).substr(2, 9)
}

function getToday(): string {
  const now = new Date()
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
}

function formatDate(timestamp: number): string {
  const d = new Date(timestamp)
  return `${d.getMonth() + 1}/${d.getDate()}`
}

Page({
  data: {
    tasks: [] as Task[],
    taskLists: [] as TaskList[],
    filteredTasks: [] as Task[],

    // 面板状态
    showListPanel: false,
    showCreateForm: false,
    showSortPanel: false,
    showSearch: false,
    showListForm: false,

    // 筛选
    currentFilter: 'all',
    currentFilterName: '全部任务',

    // 搜索
    searchKeyword: '',

    // 排序
    sortType: 'date' as 'date' | 'priority' | 'name',
    sortOrder: 'asc' as 'asc' | 'desc',

    // 编辑
    editingTaskId: '' as string,
    editingListId: '' as string,

    // 表单数据
    formData: {
      name: '',
      listId: '',
      priority: 'none' as 'none' | 'low' | 'medium' | 'high',
      dueDate: getToday(),
      dueDateStr: getToday(),
      tomatoCount: 1,
      focusMinutes: 25
    } as FormData,

    // 清单表单数据
    listFormData: {
      name: '',
      icon: '📁'
    },

    listIcons: ['📘', '📝', '🎨', '📁', '📚', '💼', '🏃', '🎯'],

    totalTaskCount: 0
  },

  onLoad() {
    this.loadData()
  },

  onShow() {
    this.loadData()
  },

  loadData() {
    const storedTasks = wx.getStorageSync(STORAGE_KEYS.TASKS) as Task[] || []
    const storedLists = wx.getStorageSync(STORAGE_KEYS.LISTS) as TaskList[] || []

    if (storedLists.length === 0) {
      const defaultLists: TaskList[] = [
        { id: 'list-1', name: '四书五经', icon: '📘', taskCount: 0 },
        { id: 'list-2', name: '学习任务', icon: '📝', taskCount: 0 },
        { id: 'list-3', name: '兴趣爱好', icon: '🎨', taskCount: 0 }
      ]
      wx.setStorageSync(STORAGE_KEYS.LISTS, defaultLists)
      this.setData({ taskLists: defaultLists })
    } else {
      this.setData({ taskLists: storedLists })
    }

    const lists = this.data.taskLists
    const tasks = storedTasks.map(task => {
      const list = lists.find(l => l.id === task.listId)
      return {
        ...task,
        listName: list ? list.name : '默认清单',
        dueDateStr: formatDate(task.dueDate)
      }
    })

    if (storedTasks.length === 0) {
      const sampleTasks: Task[] = [
        {
          id: generateId(),
          name: '背诵《论语》',
          listId: 'list-1',
          listName: '四书五经',
          priority: 'high',
          tomatoCount: 4,
          completedTomatoes: 2,
          focusMinutes: 25,
          status: 'pending',
          dueDate: Date.now(),
          dueDateStr: '今日',
          createdAt: Date.now()
        },
        {
          id: generateId(),
          name: '完成数学作业',
          listId: 'list-2',
          listName: '学习任务',
          priority: 'medium',
          tomatoCount: 2,
          completedTomatoes: 1,
          focusMinutes: 25,
          status: 'pending',
          dueDate: Date.now(),
          dueDateStr: '今日',
          createdAt: Date.now()
        },
        {
          id: generateId(),
          name: '练习书法',
          listId: 'list-3',
          listName: '兴趣爱好',
          priority: 'low',
          tomatoCount: 1,
          completedTomatoes: 0,
          focusMinutes: 30,
          status: 'pending',
          dueDate: Date.now(),
          dueDateStr: '今日',
          createdAt: Date.now()
        }
      ]
      wx.setStorageSync(STORAGE_KEYS.TASKS, sampleTasks)
      this.setData({ tasks: sampleTasks, totalTaskCount: sampleTasks.length })
    } else {
      this.setData({ tasks, totalTaskCount: tasks.length })
    }

    this.applyFilter()
  },

  saveTasks(tasks: Task[]) {
    wx.setStorageSync(STORAGE_KEYS.TASKS, tasks)
    this.setData({ totalTaskCount: tasks.length })
  },

  saveLists(lists: TaskList[]) {
    wx.setStorageSync(STORAGE_KEYS.LISTS, lists)
  },

  applyFilter() {
    let tasks = [...this.data.tasks]
    const filter = this.data.currentFilter
    const keyword = this.data.searchKeyword.trim().toLowerCase()

    // 筛选
    if (filter !== 'all') {
      tasks = tasks.filter(t => t.listId === filter)
    }

    // 搜索
    if (keyword) {
      tasks = tasks.filter(t => t.name.toLowerCase().includes(keyword))
    }

    // 排序
    const { sortType, sortOrder } = this.data
    tasks.sort((a, b) => {
      let cmp = 0
      if (sortType === 'date') {
        cmp = a.dueDate - b.dueDate
      } else if (sortType === 'priority') {
        const pOrder = { high: 3, medium: 2, low: 1, none: 0 }
        cmp = pOrder[a.priority] - pOrder[b.priority]
      } else if (sortType === 'name') {
        cmp = a.name.localeCompare(b.name)
      }
      return sortOrder === 'asc' ? cmp : -cmp
    })

    // 未完成排在前面
    tasks.sort((a, b) => {
      if (a.status === 'completed' && b.status !== 'completed') return 1
      if (a.status !== 'completed' && b.status === 'completed') return -1
      return 0
    })

    this.setData({ filteredTasks: tasks })
  },

  // ========== 面板操作 ==========
  toggleListPanel() {
    this.setData({
      showListPanel: !this.data.showListPanel,
      showSortPanel: false
    })
  },

  toggleSearch() {
    this.setData({ showSearch: !this.data.showSearch })
    if (!this.data.showSearch) {
      this.setData({ searchKeyword: '' })
      this.applyFilter()
    }
  },

  toggleSortPanel() {
    this.setData({ showSortPanel: !this.data.showSortPanel })
  },

  closeAllPanels() {
    this.setData({
      showListPanel: false,
      showSortPanel: false,
      showCreateForm: false,
      showListForm: false
    })
  },

  // ========== 搜索 ==========
  onSearchInput(e: any) {
    this.setData({ searchKeyword: e.detail.value })
    this.applyFilter()
  },

  onSearchConfirm() {
    this.applyFilter()
  },

  // ========== 筛选 ==========
  filterByList(e: any) {
    const filter = e.currentTarget.dataset.filter
    const lists = this.data.taskLists
    let name = '全部任务'
    if (filter !== 'all') {
      const list = lists.find(l => l.id === filter)
      name = list ? list.name : '未知清单'
    }
    this.setData({ currentFilter: filter, currentFilterName: name, showListPanel: false })
    this.applyFilter()
  },

  // ========== 排序 ==========
  changeSortType(e: any) {
    const type = e.currentTarget.dataset.type as 'date' | 'priority' | 'name'
    if (this.data.sortType === type) {
      this.setData({ sortOrder: this.data.sortOrder === 'asc' ? 'desc' : 'asc' })
    } else {
      this.setData({ sortType: type, sortOrder: 'asc' })
    }
    this.applyFilter()
  },

  // ========== 任务卡片操作 ==========
  onCardTap() {},

  startTask(e: any) {
    const taskId = e.currentTarget.dataset.id
    const task = this.data.tasks.find(t => t.id === taskId)
    if (!task || task.status === 'completed') return
    wx.navigateTo({
      url: `/pages/tomato/tomato?taskId=${taskId}&taskName=${encodeURIComponent(task.name)}`
    })
  },

  deleteTask(e: any) {
    const taskId = e.currentTarget.dataset.id
    wx.showModal({
      title: '确认删除',
      content: '确定要删除该任务吗？',
      success: (res) => {
        if (res.confirm) {
          const tasks = this.data.tasks.filter(t => t.id !== taskId)
          this.saveTasks(tasks)
          this.applyFilter()
          wx.showToast({ title: '任务已删除', icon: 'success' })
        }
      }
    })
  },

  // ========== 创建/编辑任务表单 ==========
  openCreateForm() {
    this.setData({
      showCreateForm: true,
      editingTaskId: '',
      formData: {
        name: '',
        listId: this.data.taskLists[0]?.id || '',
        priority: 'none',
        dueDate: getToday(),
        dueDateStr: getToday(),
        tomatoCount: 1,
        focusMinutes: 25
      }
    })
  },

  openEditForm(e: any) {
    const taskId = e.currentTarget.dataset.id
    const task = this.data.tasks.find(t => t.id === taskId)
    if (!task) return
    this.setData({
      showCreateForm: true,
      editingTaskId: taskId,
      formData: {
        name: task.name,
        listId: task.listId,
        priority: task.priority,
        dueDate: task.dueDate.toString(),
        dueDateStr: task.dueDateStr,
        tomatoCount: task.tomatoCount,
        focusMinutes: task.focusMinutes
      }
    })
  },

  closeCreateForm() {
    this.setData({ showCreateForm: false, editingTaskId: '' })
  },

  onFormNameInput(e: any) {
    this.setData({ 'formData.name': e.detail.value })
  },

  onListChange(e: any) {
    const index = e.detail.value
    const list = this.data.taskLists[index]
    if (list) {
      this.setData({ 'formData.listId': list.id })
    }
  },

  onPriorityChange(e: any) {
    const priority = e.currentTarget.dataset.priority as 'none' | 'low' | 'medium' | 'high'
    this.setData({ 'formData.priority': priority })
  },

  onDateChange(e: any) {
    const date = e.detail.value
    const d = new Date(date)
    const str = `${d.getMonth() + 1}/${d.getDate()}`
    this.setData({ 'formData.dueDate': date, 'formData.dueDateStr': str })
  },

  decTomatoCount() {
    const v = this.data.formData.tomatoCount
    if (v > 1) this.setData({ 'formData.tomatoCount': v - 1 })
  },

  incTomatoCount() {
    const v = this.data.formData.tomatoCount
    if (v < 8) this.setData({ 'formData.tomatoCount': v + 1 })
  },

  decFocusMinutes() {
    const v = this.data.formData.focusMinutes
    if (v > 5) this.setData({ 'formData.focusMinutes': v - 5 })
  },

  incFocusMinutes() {
    const v = this.data.formData.focusMinutes
    if (v < 60) this.setData({ 'formData.focusMinutes': v + 5 })
  },

  submitTask() {
    const { name, listId, priority, dueDate, tomatoCount, focusMinutes } = this.data.formData

    if (!name.trim()) {
      wx.showToast({ title: '请输入任务名称', icon: 'none' })
      return
    }
    if (!listId) {
      wx.showToast({ title: '请选择所属清单', icon: 'none' })
      return
    }

    const list = this.data.taskLists.find(l => l.id === listId)
    const listName = list ? list.name : '默认清单'
    const editingId = this.data.editingTaskId

    let tasks = [...this.data.tasks]

    if (editingId) {
      // 编辑
      tasks = tasks.map(t => {
        if (t.id === editingId) {
          return {
            ...t,
            name: name.trim(),
            listId,
            listName,
            priority,
            dueDate: new Date(dueDate).getTime(),
            dueDateStr: this.data.formData.dueDateStr,
            tomatoCount,
            focusMinutes
          }
        }
        return t
      })
    } else {
      // 新建
      const newTask: Task = {
        id: generateId(),
        name: name.trim(),
        listId,
        listName,
        priority,
        tomatoCount,
        completedTomatoes: 0,
        focusMinutes,
        status: 'pending',
        dueDate: new Date(dueDate).getTime(),
        dueDateStr: this.data.formData.dueDateStr,
        createdAt: Date.now()
      }
      tasks.unshift(newTask)
    }

    this.saveTasks(tasks)
    this.applyFilter()
    this.closeCreateForm()
    wx.showToast({
      title: editingId ? '任务已保存' : '任务已创建',
      icon: 'success'
    })
  },

  // ========== 清单管理 ==========
  openCreateList() {
    this.setData({
      showListForm: true,
      editingListId: '',
      listFormData: { name: '', icon: '📁' }
    })
  },

  openEditList(e: any) {
    const listId = e.currentTarget.dataset.id
    const list = this.data.taskLists.find(l => l.id === listId)
    if (!list) return
    this.setData({
      showListForm: true,
      editingListId: listId,
      listFormData: { name: list.name, icon: list.icon }
    })
  },

  closeListForm() {
    this.setData({ showListForm: false, editingListId: '' })
  },

  onListFormNameInput(e: any) {
    this.setData({ 'listFormData.name': e.detail.value })
  },

  onIconSelect(e: any) {
    this.setData({ 'listFormData.icon': e.currentTarget.dataset.icon })
  },

  submitListForm() {
    const { name, icon } = this.data.listFormData
    if (!name.trim()) {
      wx.showToast({ title: '请输入清单名称', icon: 'none' })
      return
    }

    const lists = [...this.data.taskLists]
    const editingId = this.data.editingListId

    if (editingId) {
      lists.forEach(l => {
        if (l.id === editingId) {
          l.name = name.trim()
          l.icon = icon
        }
      })
      // 更新任务的清单名称
      const tasks = [...this.data.tasks].map(t => {
        if (t.listId === editingId) t.listName = name.trim()
        return t
      })
      this.saveTasks(tasks)
    } else {
      lists.push({
        id: generateId(),
        name: name.trim(),
        icon,
        taskCount: 0
      })
    }

    this.saveLists(lists)
    this.setData({ taskLists: lists })
    this.applyFilter()
    this.closeListForm()
    wx.showToast({
      title: editingId ? '清单已更新' : '清单已创建',
      icon: 'success'
    })
  },

  deleteList(e: any) {
    const listId = e.currentTarget.dataset.id
    wx.showModal({
      title: '确认删除',
      content: '删除清单后，该清单下的任务不会被删除，是否继续？',
      success: (res) => {
        if (res.confirm) {
          let lists = this.data.taskLists.filter(l => l.id !== listId)
          this.saveLists(lists)
          this.setData({ taskLists: lists })
          if (this.data.currentFilter === listId) {
            this.setData({ currentFilter: 'all', currentFilterName: '全部任务' })
          }
          this.applyFilter()
          wx.showToast({ title: '清单已删除', icon: 'success' })
        }
      }
    })
  },

  // ========== 辅助方法 ==========
  getListName(listId: string): string {
    const list = this.data.taskLists.find(l => l.id === listId)
    return list ? list.name : '请选择清单'
  }
})

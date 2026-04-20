// 任务页面
import { storage, Task, TaskList } from '../../utils/storage'
import { generateId, formatDate } from '../../utils/algorithm'

interface FormData {
  name: string
  listId: string
  priority: 'none' | 'low' | 'medium' | 'high'
  dueDate: string
  dueDateStr: string
  tomatoCount: number
  focusMinutes: number
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
      dueDate: '',
      dueDateStr: '',
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
    const tasks = storage.getTasks()
    const lists = storage.getLists()

    const tasksWithNames = tasks.map(task => {
      const list = lists.find(l => l.id === task.listId)
      return {
        ...task,
        listName: list ? list.name : '默认清单',
        dueDateStr: formatDate(task.dueDate)
      }
    })

    // 初始化默认任务（首次使用）
    if (tasks.length === 0) {
      const now = Date.now()
      const todayStr = formatDate(now)
      const defaultTasks: Task[] = [
        {
          id: generateId(), name: '背诵《论语》', listId: 'list-1',
          listName: '四书五经', priority: 'high', tomatoCount: 4,
          completedTomatoes: 2, focusMinutes: 25, status: 'pending',
          dueDate: now, dueDateStr: todayStr, createdAt: now
        },
        {
          id: generateId(), name: '完成数学作业', listId: 'list-2',
          listName: '学习任务', priority: 'medium', tomatoCount: 2,
          completedTomatoes: 1, focusMinutes: 25, status: 'pending',
          dueDate: now, dueDateStr: todayStr, createdAt: now
        },
        {
          id: generateId(), name: '练习书法', listId: 'list-3',
          listName: '兴趣爱好', priority: 'low', tomatoCount: 1,
          completedTomatoes: 0, focusMinutes: 30, status: 'pending',
          dueDate: now, dueDateStr: todayStr, createdAt: now
        }
      ]
      storage.setTasks(defaultTasks)
      this.setData({ tasks: defaultTasks, taskLists: lists, totalTaskCount: defaultTasks.length })
    } else {
      this.setData({ tasks: tasksWithNames, taskLists: lists, totalTaskCount: tasks.length })
    }

    this.applyFilter()
  },

  applyFilter() {
    let tasks = [...this.data.tasks]
    const filter = this.data.currentFilter
    const keyword = this.data.searchKeyword.trim().toLowerCase()

    if (filter !== 'all') {
      tasks = tasks.filter(t => t.listId === filter)
    }

    if (keyword) {
      tasks = tasks.filter(t => t.name.toLowerCase().includes(keyword))
    }

    const { sortType, sortOrder } = this.data
    tasks.sort((a, b) => {
      let cmp = 0
      if (sortType === 'date') {
        cmp = a.dueDate - b.dueDate
      } else if (sortType === 'priority') {
        const pOrder: Record<string, number> = { high: 3, medium: 2, low: 1, none: 0 }
        cmp = pOrder[a.priority] - pOrder[b.priority]
      } else {
        cmp = a.name.localeCompare(b.name)
      }
      return sortOrder === 'asc' ? cmp : -cmp
    })

    tasks.sort((a, b) => {
      if (a.status === 'completed' && b.status !== 'completed') return 1
      if (a.status !== 'completed' && b.status === 'completed') return -1
      return 0
    })

    this.setData({ filteredTasks: tasks })
  },

  // ========== 面板操作 ==========
  toggleListPanel() {
    this.setData({ showListPanel: !this.data.showListPanel, showSortPanel: false })
  },

  toggleSearch() {
    const show = !this.data.showSearch
    this.setData({ showSearch: show })
    if (!show) {
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

  // ========== 任务操作 ==========
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
          storage.deleteTask(taskId)
          const tasks = this.data.tasks.filter(t => t.id !== taskId)
          this.setData({ tasks })
          this.applyFilter()
          wx.showToast({ title: '任务已删除', icon: 'success' })
        }
      }
    })
  },

  // ========== 创建/编辑任务 ==========
  openCreateForm() {
    const lists = storage.getLists()
    const today = formatDate(Date.now())
    this.setData({
      showCreateForm: true,
      editingTaskId: '',
      taskLists: lists,
      formData: {
        name: '',
        listId: lists[0]?.id || '',
        priority: 'none',
        dueDate: '',
        dueDateStr: today,
        tomatoCount: 1,
        focusMinutes: 25
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
    if (list) this.setData({ 'formData.listId': list.id })
  },

  onPriorityChange(e: any) {
    this.setData({ 'formData.priority': e.currentTarget.dataset.priority })
  },

  onDateChange(e: any) {
    const date = e.detail.value
    const d = new Date(date)
    this.setData({
      'formData.dueDate': date,
      'formData.dueDateStr': formatDate(d)
    })
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
    const { name, listId, priority, dueDate, tomatoCount, focusMinutes, dueDateStr } = this.data.formData

    if (!name.trim()) {
      wx.showToast({ title: '请输入任务名称', icon: 'none' })
      return
    }
    if (!listId) {
      wx.showToast({ title: '请选择所属清单', icon: 'none' })
      return
    }

    const lists = storage.getLists()
    const list = lists.find(l => l.id === listId)
    const listName = list ? list.name : '默认清单'
    const editingId = this.data.editingTaskId

    if (editingId) {
      storage.updateTask(editingId, {
        name: name.trim(), listId, listName, priority,
        tomatoCount, focusMinutes,
        dueDate: dueDate ? new Date(dueDate).getTime() : Date.now(),
        dueDateStr
      })
    } else {
      const newTask: Task = {
        id: generateId(), name: name.trim(), listId, listName, priority,
        tomatoCount, completedTomatoes: 0, focusMinutes,
        status: 'pending',
        dueDate: dueDate ? new Date(dueDate).getTime() : Date.now(),
        dueDateStr, createdAt: Date.now()
      }
      storage.addTask(newTask)
    }

    const tasks = storage.getTasks().map(t => ({
      ...t,
      listName: lists.find(l => l.id === t.listId)?.name || '默认清单',
      dueDateStr: formatDate(t.dueDate)
    }))
    this.setData({ tasks })
    this.applyFilter()
    this.closeCreateForm()
    wx.showToast({ title: editingId ? '任务已保存' : '任务已创建', icon: 'success' })
  },

  // ========== 清单管理 ==========
  openCreateList() {
    this.setData({ showListForm: true, editingListId: '', listFormData: { name: '', icon: '📁' } })
  },

  openEditList(e: any) {
    const listId = e.currentTarget.dataset.id
    const list = this.data.taskLists.find(l => l.id === listId)
    if (!list) return
    this.setData({ showListForm: true, editingListId: listId, listFormData: { name: list.name, icon: list.icon } })
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

    const editingId = this.data.editingListId
    if (editingId) {
      storage.updateList(editingId, { name: name.trim(), icon })
      const tasks = storage.getTasks().map(t => {
        if (t.listId === editingId) return { ...t, listName: name.trim() }
        return t
      })
      storage.setTasks(tasks)
    } else {
      storage.addList({ id: generateId(), name: name.trim(), icon, taskCount: 0 })
    }

    const lists = storage.getLists()
    this.setData({ taskLists: lists })
    this.applyFilter()
    this.closeListForm()
    wx.showToast({ title: editingId ? '清单已更新' : '清单已创建', icon: 'success' })
  },

  deleteList(e: any) {
    const listId = e.currentTarget.dataset.id
    wx.showModal({
      title: '确认删除',
      content: '删除清单后，该清单下的任务不会被删除，是否继续？',
      success: (res) => {
        if (res.confirm) {
          storage.deleteList(listId)
          const lists = storage.getLists()
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

  getListName(listId: string): string {
    const list = this.data.taskLists.find(l => l.id === listId)
    return list ? list.name : '请选择清单'
  }
})

import { storage, FocusRecord } from '../../utils/storage'
import { PomodoroQueue, generateId, getToday } from '../../utils/algorithm'
import { audioManager, WhiteNoiseType } from '../../utils/audio'

let _timer: ReturnType<typeof setInterval> | null = null
let _pomodoro!: PomodoroQueue
let _focusStartTime: number = 0

Page({
  data: {
    taskId: '',
    taskName: '',
    mode: 'work' as 'work' | 'rest' | 'complete',

    // 计时器
    remainingSeconds: 0,
    remainingTimeStr: '25:00',
    progress: 0,

    // 番茄状态
    currentTomato: 1,
    totalTomatoes: 4,
    totalFocusMinutes: 0,

    // 控制
    isPaused: false,
    isSoundOn: false,
    whiteNoiseType: 'rain' as WhiteNoiseType,
    whiteNoiseLabel: '🌧️ 雨声'
  },

  onLoad(options: any) {
    if (options.taskId) {
      const task = storage.getTaskById(options.taskId)
      const settings = storage.getSettings()

      this.setData({
        taskId: options.taskId,
        taskName: task?.name || decodeURIComponent(options.taskName || '未知任务'),
        totalTomatoes: task?.tomatoCount || 4,
        totalFocusMinutes: task?.focusMinutes || 25,
        remainingSeconds: (task?.focusMinutes || 25) * 60,
        whiteNoiseType: settings.whiteNoise,
        whiteNoiseLabel: audioManager.getWhiteNoiseLabel(settings.whiteNoise)
      })

      _pomodoro = new PomodoroQueue(
        task?.focusMinutes || 25,
        settings.restDuration,
        task?.tomatoCount || 4
      )

      this.updateTimeStr()
      this.updateProgress()
    }
  },

  onShow() {
    if (this.data.mode === 'work' && !_timer) {
      this.startTimer()
      if (this.data.whiteNoiseType !== 'none') {
        audioManager.playWhiteNoise(this.data.whiteNoiseType)
        this.setData({ isSoundOn: true })
      }
    }
  },

  onHide() {
    if (_timer) {
      clearInterval(_timer)
      _timer = null
    }
  },

  onUnload() {
    if (_timer) {
      clearInterval(_timer)
      _timer = null
    }
    audioManager.stopWhiteNoise()
  },

  // ========== 计时器 ==========
  startTimer() {
    if (_timer) return
    _focusStartTime = Date.now()

    _timer = setInterval(() => {
      if (this.data.isPaused) return

      const newSeconds = this.data.remainingSeconds - 1
      if (newSeconds <= 0) {
        this.onTimerComplete()
        return
      }

      this.setData({ remainingSeconds: newSeconds })
      this.updateTimeStr()
      this.updateProgress()
    }, 1000)
  },

  stopTimer() {
    if (_timer) {
      clearInterval(_timer)
      _timer = null
    }
  },

  updateTimeStr() {
    const mins = Math.floor(this.data.remainingSeconds / 60)
    const secs = this.data.remainingSeconds % 60
    this.setData({ remainingTimeStr: `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}` })
  },

  updateProgress() {
    const totalSeconds = this.data.mode === 'work'
      ? (this.data.totalFocusMinutes * 60)
      : (storage.getSettings().restDuration * 60)
    const progress = Math.round(((totalSeconds - this.data.remainingSeconds) / totalSeconds) * 100)
    this.setData({ progress })
  },

  // ========== 计时完成 ==========
  onTimerComplete() {
    this.stopTimer()
    audioManager.stopWhiteNoise()

    if (this.data.mode === 'work') {
      // 专注完成：记录数据
      const actualDuration = Math.round((Date.now() - _focusStartTime) / 60000)
      const record: FocusRecord = {
        id: generateId(),
        taskId: this.data.taskId,
        taskName: this.data.taskName,
        duration: actualDuration,
        date: getToday(),
        timestamp: Date.now()
      }
      storage.addFocusRecord(record)

      // 更新任务的已完成番茄数
      const task = storage.getTaskById(this.data.taskId)
      if (task) {
        const newCompleted = task.completedTomatoes + 1
        storage.updateTask(this.data.taskId, {
          completedTomatoes: newCompleted,
          status: newCompleted >= task.tomatoCount ? 'completed' : 'pending'
        })
      }

      // 播放休息铃声
      const settings = storage.getSettings()
      audioManager.playRestBell(settings.restSound)

      // 切换状态
      const nextState = _pomodoro.next()
      if (nextState === 'complete') {
        this.setData({ mode: 'complete', progress: 100 })
      } else {
        const restDuration = settings.restDuration
        this.setData({
          mode: 'rest',
          currentTomato: _pomodoro.getCurrentCycle(),
          remainingSeconds: restDuration * 60,
          progress: 0
        })
        this.updateTimeStr()
        this.startTimer()
      }
    } else if (this.data.mode === 'rest') {
      // 休息完成：开始下一个专注
      audioManager.playRestBell(storage.getSettings().restSound)
      const workMinutes = this.data.totalFocusMinutes
      this.setData({
        mode: 'work',
        currentTomato: _pomodoro.getCurrentCycle(),
        remainingSeconds: workMinutes * 60,
        progress: 0
      })
      this.updateTimeStr()
      this.startTimer()
      if (this.data.isSoundOn && this.data.whiteNoiseType !== 'none') {
        audioManager.playWhiteNoise(this.data.whiteNoiseType)
      }
    }
  },

  // ========== 控制 ==========
  togglePause() {
    const isPaused = !this.data.isPaused
    this.setData({ isPaused })
    if (isPaused) {
      audioManager.stopWhiteNoise()
    } else {
      if (this.data.whiteNoiseType !== 'none') {
        audioManager.playWhiteNoise(this.data.whiteNoiseType)
      }
    }
    wx.vibrateShort({ type: 'light' })
  },

  confirmEnd() {
    wx.showModal({
      title: '确认结束',
      content: '确定要结束当前专注吗？专注数据不会被保存。',
      success: (res) => {
        if (res.confirm) {
          this.stopTimer()
          audioManager.stopWhiteNoise()
          wx.navigateBack()
        }
      }
    })
  },

  skipRest() {
    if (this.data.mode !== 'rest') return
    this.stopTimer()
    audioManager.stopWhiteNoise()
    const nextState = _pomodoro.skipRest()
    if (nextState === 'complete') {
      this.setData({ mode: 'complete', progress: 100 })
    } else {
      const workMinutes = this.data.totalFocusMinutes
      this.setData({
        mode: 'work',
        currentTomato: _pomodoro.getCurrentCycle(),
        remainingSeconds: workMinutes * 60,
        progress: 0
      })
      this.updateTimeStr()
      this.startTimer()
      if (this.data.isSoundOn && this.data.whiteNoiseType !== 'none') {
        audioManager.playWhiteNoise(this.data.whiteNoiseType)
      }
    }
    wx.vibrateShort({ type: 'light' })
  },

  toggleSound() {
    const isSoundOn = !this.data.isSoundOn
    this.setData({ isSoundOn })
    if (isSoundOn && this.data.mode === 'work' && !this.data.isPaused) {
      audioManager.playWhiteNoise(this.data.whiteNoiseType)
    } else {
      audioManager.stopWhiteNoise()
    }
    wx.vibrateShort({ type: 'light' })
  },

  goBack() {
    wx.navigateBack()
  },

  onBack() {
    wx.showModal({
      title: '确认返回',
      content: '专注计时将停止，是否确认返回？',
      success: (res) => {
        if (res.confirm) {
          this.stopTimer()
          audioManager.stopWhiteNoise()
          wx.navigateBack()
        }
      }
    })
  }
})

// 设置页面
import { storage } from '../../utils/storage'

Page({
  data: {
    theme: 'light' as 'light' | 'dark' | 'auto',
    whiteNoise: 'rain' as 'rain' | 'waves' | 'fire' | 'gugin' | 'none',
    restSound: 'guzheng' as 'guzheng' | 'bowl' | 'birds' | 'none',
    restDuration: 5,

    currentWhiteNoiseLabel: '雨声',
    currentRestSoundLabel: '古筝音',

    whiteNoiseDropdownOpen: false,
    restSoundDropdownOpen: false,

    settings: {
      themeOptions: [
        { value: 'light', label: '浅色模式', selected: true },
        { value: 'dark', label: '深色模式', selected: false },
        { value: 'auto', label: '随系统', selected: false }
      ],
      whiteNoiseOptions: [
        { value: 'rain', label: '🌧️ 雨声', selected: true },
        { value: 'waves', label: '🌊 海浪', selected: false },
        { value: 'fire', label: '🔥 篝火', selected: false },
        { value: 'gugin', label: '🎵 古琴', selected: false },
        { value: 'none', label: '🔇 无', selected: false }
      ],
      restSoundOptions: [
        { value: 'guzheng', label: '🎵 古筝音', selected: true },
        { value: 'bowl', label: '🪘 钵音', selected: false },
        { value: 'birds', label: '🐦 鸟鸣', selected: false },
        { value: 'none', label: '🔇 无', selected: false }
      ]
    } as {
      themeOptions: Array<{ value: string; label: string; selected: boolean }>
      whiteNoiseOptions: Array<{ value: string; label: string; selected: boolean }>
      restSoundOptions: Array<{ value: string; label: string; selected: boolean }>
    }
  },

  onLoad() {
    this.loadSettings()
  },

  onShow() {
    this.loadSettings()
  },

  loadSettings() {
    const settings = storage.getSettings()
    this.setData({
      theme: settings.theme,
      whiteNoise: settings.whiteNoise,
      restSound: settings.restSound,
      restDuration: settings.restDuration,
      currentWhiteNoiseLabel: this.getWhiteNoiseLabel(settings.whiteNoise),
      currentRestSoundLabel: this.getRestSoundLabel(settings.restSound)
    })

    // 更新选项选中状态
    const themeOptions = this.data.settings.themeOptions.map(o => ({
      ...o, selected: o.value === settings.theme
    }))
    const whiteNoiseOptions = this.data.settings.whiteNoiseOptions.map(o => ({
      ...o, selected: o.value === settings.whiteNoise
    }))
    const restSoundOptions = this.data.settings.restSoundOptions.map(o => ({
      ...o, selected: o.value === settings.restSound
    }))

    this.setData({
      'settings.themeOptions': themeOptions,
      'settings.whiteNoiseOptions': whiteNoiseOptions,
      'settings.restSoundOptions': restSoundOptions
    })

    // 应用主题
    this.applyTheme(settings.theme)
  },

  applyTheme(theme: 'light' | 'dark' | 'auto') {
    let bgColor = '#f8f4e9'
    if (theme === 'dark') {
      bgColor = '#2c2c2c'
    } else if (theme === 'light') {
      bgColor = '#f8f4e9'
    }

    wx.setBackgroundColor({ backgroundColor: bgColor })
  },

  toggleWhiteNoiseDropdown() {
    this.setData({
      whiteNoiseDropdownOpen: !this.data.whiteNoiseDropdownOpen,
      restSoundDropdownOpen: false
    })
  },

  toggleRestSoundDropdown() {
    this.setData({
      restSoundDropdownOpen: !this.data.restSoundDropdownOpen,
      whiteNoiseDropdownOpen: false
    })
  },

  selectTheme(e: any) {
    const theme = e.currentTarget.dataset.theme as 'light' | 'dark' | 'auto'
    const updatedOptions = this.data.settings.themeOptions.map(option => ({
      ...option,
      selected: option.value === theme
    }))

    storage.updateSettings({ theme })
    this.applyTheme(theme)

    this.setData({
      theme,
      'settings.themeOptions': updatedOptions
    })

    wx.showToast({ title: '主题已切换', icon: 'success' })
  },

  selectWhiteNoise(e: any) {
    const noise = e.currentTarget.dataset.noise as 'rain' | 'waves' | 'fire' | 'gugin' | 'none'
    const updatedOptions = this.data.settings.whiteNoiseOptions.map(option => ({
      ...option,
      selected: option.value === noise
    }))

    storage.updateSettings({ whiteNoise: noise })

    this.setData({
      whiteNoise: noise,
      currentWhiteNoiseLabel: this.getWhiteNoiseLabel(noise),
      'settings.whiteNoiseOptions': updatedOptions,
      whiteNoiseDropdownOpen: false
    })

    wx.showToast({ title: `已选择：${this.getWhiteNoiseLabel(noise)}`, icon: 'none' })
  },

  selectRestSound(e: any) {
    const sound = e.currentTarget.dataset.sound as 'guzheng' | 'bowl' | 'birds' | 'none'
    const updatedOptions = this.data.settings.restSoundOptions.map(option => ({
      ...option,
      selected: option.value === sound
    }))

    storage.updateSettings({ restSound: sound })

    this.setData({
      restSound: sound,
      currentRestSoundLabel: this.getRestSoundLabel(sound),
      'settings.restSoundOptions': updatedOptions,
      restSoundDropdownOpen: false
    })

    wx.showToast({ title: `已选择：${this.getRestSoundLabel(sound)}`, icon: 'none' })
  },

  decreaseRestDuration() {
    if (this.data.restDuration > 1) {
      const newDuration = this.data.restDuration - 1
      storage.updateSettings({ restDuration: newDuration })
      this.setData({ restDuration: newDuration })
    }
  },

  increaseRestDuration() {
    if (this.data.restDuration < 30) {
      const newDuration = this.data.restDuration + 1
      storage.updateSettings({ restDuration: newDuration })
      this.setData({ restDuration: newDuration })
    }
  },

  showAbout() {
    wx.showModal({
      title: '关于 Satori',
      content: 'Satori Mini Program v1.0.0\n\n以东方美学承载任务、番茄钟、打卡与专注统计。',
      showCancel: false,
      confirmText: '知道了'
    })
  },

  getWhiteNoiseLabel(value: string): string {
    const map: Record<string, string> = {
      rain: '🌧️ 雨声',
      waves: '🌊 海浪',
      fire: '🔥 篝火',
      gugin: '🎵 古琴',
      none: '🔇 无'
    }
    return map[value] || '无'
  },

  getRestSoundLabel(value: string): string {
    const map: Record<string, string> = {
      guzheng: '🎵 古筝音',
      bowl: '🪘 钵音',
      birds: '🐦 鸟鸣',
      none: '🔇 无'
    }
    return map[value] || '无'
  }
})

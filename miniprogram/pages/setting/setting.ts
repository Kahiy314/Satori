Page({
  data: {
    theme: 'light',
    whiteNoise: 'rain',
    restSound: 'guzheng',
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
        { value: 'rain', label: '雨声', selected: true },
        { value: 'waves', label: '海浪', selected: false },
        { value: 'fire', label: '篝火', selected: false },
        { value: 'gugin', label: '古琴', selected: false },
        { value: 'none', label: '无', selected: false }
      ],
      restSoundOptions: [
        { value: 'guzheng', label: '古筝音', selected: true },
        { value: 'bowl', label: '钵音', selected: false },
        { value: 'birds', label: '鸟鸣', selected: false },
        { value: 'none', label: '无', selected: false }
      ]
    }
  },

  onLoad() {
    console.log('设置页面加载')
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
    const theme = e.currentTarget.dataset.theme
    const updatedOptions = this.data.settings.themeOptions.map(option => ({
      ...option,
      selected: option.value === theme
    }))

    this.setData({
      theme: theme,
      'settings.themeOptions': updatedOptions
    })

    wx.showToast({
      title: '主题已切换',
      icon: 'success'
    })
  },

  selectWhiteNoise(e: any) {
    const noise = e.currentTarget.dataset.noise
    const updatedOptions = this.data.settings.whiteNoiseOptions.map(option => ({
      ...option,
      selected: option.value === noise
    }))

    const selectedOption = updatedOptions.find(option => option.selected)

    this.setData({
      whiteNoise: noise,
      'settings.whiteNoiseOptions': updatedOptions,
      currentWhiteNoiseLabel: selectedOption ? selectedOption.label : '无',
      whiteNoiseDropdownOpen: false
    })
  },

  selectRestSound(e: any) {
    const sound = e.currentTarget.dataset.sound
    const updatedOptions = this.data.settings.restSoundOptions.map(option => ({
      ...option,
      selected: option.value === sound
    }))

    const selectedOption = updatedOptions.find(option => option.selected)

    this.setData({
      restSound: sound,
      'settings.restSoundOptions': updatedOptions,
      currentRestSoundLabel: selectedOption ? selectedOption.label : '无',
      restSoundDropdownOpen: false
    })
  },

  decreaseRestDuration() {
    if (this.data.restDuration > 1) {
      this.setData({
        restDuration: this.data.restDuration - 1
      })
    }
  },

  increaseRestDuration() {
    if (this.data.restDuration < 30) {
      this.setData({
        restDuration: this.data.restDuration + 1
      })
    }
  },

  showAbout() {
    wx.showModal({
      title: '关于',
      content: '香韵番茄钟 v1.0.0\n弘扬国风文化，专注学习效率',
      showCancel: false
    })
  }
})

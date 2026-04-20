// app.ts
import { storage } from './utils/storage'

App<IAppOption>({
  globalData: {},

  onLaunch() {
    // 初始化默认数据
    storage.initDefaultData()

    // 获取主题设置并应用
    const settings = storage.getSettings()
    if (settings.theme === 'dark') {
      wx.setBackgroundColor({ backgroundColor: '#2c2c2c' })
    }

    // 展示本地存储能力
    const logs = wx.getStorageSync('logs') || []
    logs.unshift(Date.now())
    wx.setStorageSync('logs', logs)

    // 登录
    wx.login({
      success: res => {
        console.log('[登录] code:', res.code)
      }
    })

    // 监听主题变化
    wx.onThemeChange((res) => {
      const settings = storage.getSettings()
      if (settings.theme === 'auto') {
        const bg = res.theme === 'dark' ? '#2c2c2c' : '#f8f4e9'
        wx.setBackgroundColor({ backgroundColor: bg })
      }
    })
  }
})

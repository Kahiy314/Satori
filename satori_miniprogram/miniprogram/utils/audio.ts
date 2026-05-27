// ========== 音频管理 ==========

export type WhiteNoiseType = 'rain' | 'waves' | 'fire' | 'guqin' | 'none'
export type RestSoundType = 'guzheng' | 'bowl' | 'birds' | 'none'

const WHITE_NOISE_FILES: Record<WhiteNoiseType, string> = {
  rain: 'rain.mp3',
  waves: 'wave.mp3',
  fire: 'fire.mp3',
  guqin: 'guqin.mp3',
  none: ''
}

const REST_SOUND_FILES: Record<RestSoundType, string> = {
  guzheng: 'guzheng.mp3',
  bowl: 'bowl.mp3',
  birds: 'bird.mp3',
  none: ''
}

const WHITE_NOISE_LABELS: Record<WhiteNoiseType, string> = {
  rain: '🌧️ 雨声',
  waves: '🌊 海浪',
  fire: '🔥 篝火',
  guqin: '🎵 古琴',
  none: '🔇 无'
}

const REST_SOUND_LABELS: Record<RestSoundType, string> = {
  guzheng: '🎵 古筝音',
  bowl: '🪘 钵音',
  birds: '🐦 鸟鸣',
  none: '🔇 无'
}

let currentAudio: WechatMiniprogram.InnerAudioContext | null = null
let restBellAudio: WechatMiniprogram.InnerAudioContext | null = null
let isPlaying: boolean = false

class AudioManager {
  // 播放白噪音
  playWhiteNoise(type: WhiteNoiseType): void {
    this.stopWhiteNoise()
    if (type === 'none') return

    const filename = WHITE_NOISE_FILES[type]
    if (!filename) return

    currentAudio = wx.createInnerAudioContext()
    currentAudio.obeyMuteSwitch = false
    currentAudio.src = `/assets/audio/white_noise/${filename}`
    currentAudio.loop = true
    currentAudio.play()
    isPlaying = true

    currentAudio.onError((err: WechatMiniprogram.InnerAudioContextOnErrorCallbackResult) => {
      console.warn('白噪音播放失败:', err)
      isPlaying = false
    })
  }

  // 停止白噪音
  stopWhiteNoise(): void {
    if (currentAudio) {
      currentAudio.stop()
      currentAudio.destroy()
      currentAudio = null
      isPlaying = false
    }
  }

  // 切换白噪音
  toggleWhiteNoise(current: WhiteNoiseType): WhiteNoiseType {
    const order: WhiteNoiseType[] = ['rain', 'waves', 'fire', 'guqin', 'none']
    const index = order.indexOf(current)
    const next = order[(index + 1) % order.length]
    if (next === 'none') {
      this.stopWhiteNoise()
    } else {
      this.playWhiteNoise(next)
    }
    return next
  }

  // 播放休息铃声
  playRestBell(type: RestSoundType): void {
    if (restBellAudio) {
      restBellAudio.stop()
      restBellAudio.destroy()
    }
    if (type === 'none') return

    const filename = REST_SOUND_FILES[type]
    if (!filename) return

    restBellAudio = wx.createInnerAudioContext()
    restBellAudio.obeyMuteSwitch = false
    restBellAudio.src = `/assets/audio/rest_bell/${filename}`
    restBellAudio.play()

    restBellAudio.onEnded(() => {
      if (restBellAudio) {
        restBellAudio.destroy()
        restBellAudio = null
      }
    })
  }

  // 获取白噪音标签
  getWhiteNoiseLabel(type: WhiteNoiseType): string {
    return WHITE_NOISE_LABELS[type] || '🔇 无'
  }

  // 获取铃声标签
  getRestSoundLabel(type: RestSoundType): string {
    return REST_SOUND_LABELS[type] || '🔇 无'
  }

  // 获取白噪音选项列表
  getWhiteNoiseOptions(): Array<{ value: WhiteNoiseType; label: string }> {
    return (Object.keys(WHITE_NOISE_FILES) as WhiteNoiseType[]).map(key => ({
      value: key,
      label: WHITE_NOISE_LABELS[key]
    }))
  }

  // 获取铃声选项列表
  getRestSoundOptions(): Array<{ value: RestSoundType; label: string }> {
    return (Object.keys(REST_SOUND_FILES) as RestSoundType[]).map(key => ({
      value: key,
      label: REST_SOUND_LABELS[key]
    }))
  }

  // 检查是否正在播放
  getIsPlaying(): boolean {
    return isPlaying
  }
}

export const audioManager = new AudioManager()

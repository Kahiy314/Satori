// ========== AI 总结入口 ==========
//
// 不要在小程序端硬编码第三方 API key。正式接入时应改为调用你自己的
// 云函数或服务端代理，由服务端持有 DeepSeek / OpenAI 等供应商密钥。

const AI_CONFIG = {
  url: '',
  apiKey: '',
  model: 'deepseek-chat'
}

interface Message {
  role: 'system' | 'user'
  content: string
}

const SYSTEM_PROMPT = `你是一位儒家文化学习顾问，根据用户的番茄钟专注数据，
提供温暖、鼓励且富有国学智慧的学习总结与建议。
请用简洁、有文采的语言，控制在100字以内。`

interface AIResponse {
  content: string
  lastUpdate: string
}

class AIManager {
  private requestId: number = 0

  // 生成学习总结
  async generateSummary(data: {
    todayFocus: number
    todayTasks: number
    weekFocus: number
    weekTasks: number
    totalFocus: number
    totalTasks: number
    topTaskName?: string
    topTaskMinutes?: number
  }): Promise<AIResponse> {
    const prompt = `请根据以下番茄钟专注数据，用温暖有文采的语言生成一段学习总结（100字以内）：
今日专注：${data.todayFocus}分钟，完成${data.todayTasks}个任务
本周专注：${data.weekFocus}分钟，完成${data.weekTasks}个任务
总专注：${data.totalFocus}分钟，总任务${data.totalTasks}个${data.topTaskName ? `\n最专注的任务：${data.topTaskName}（${data.topTaskMinutes || 0}分钟）` : ''}
请结合儒家文化给出鼓励和建议。`

    const content = await this.callAPI(prompt)
    return {
      content,
      lastUpdate: this.formatTime()
    }
  }

  // 调用 DeepSeek API
  private async callAPI(userPrompt: string): Promise<string> {
    if (!AI_CONFIG.url || !AI_CONFIG.apiKey) {
      console.warn('[AI] 未配置服务端代理，使用本地默认总结。')
      return this.getDefaultSummary()
    }

    const requestId = ++this.requestId
    console.log(`[AI] 请求 #${requestId}:`, userPrompt.substring(0, 50) + '...')

    try {
      const response = await new Promise<WechatMiniprogram.RequestSuccessCallbackResult>((resolve, reject) => {
        wx.request({
          url: AI_CONFIG.url,
          method: 'POST',
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${AI_CONFIG.apiKey}`
          },
          data: {
            model: AI_CONFIG.model,
            messages: [
              { role: 'system', content: SYSTEM_PROMPT },
              { role: 'user', content: userPrompt }
            ] as Message[],
            max_tokens: 200,
            temperature: 0.7
          },
          success: resolve,
          fail: reject
        })
      })

      if (requestId !== this.requestId) {
        console.log(`[AI] 请求 #${requestId} 已废弃（被新请求取代）`)
        return ''
      }

      const res = response.data as any
      if (res.error) {
        console.error('[AI] API 错误:', res.error)
        return this.getDefaultSummary()
      }

      const content = res.choices?.[0]?.message?.content as string
      console.log(`[AI] 响应 #${requestId}:`, content?.substring(0, 80))
      return content || this.getDefaultSummary()
    } catch (err) {
      console.error('[AI] 请求失败:', err)
      return this.getDefaultSummary()
    }
  }

  private formatTime(): string {
    const now = new Date()
    const y = now.getFullYear()
    const m = String(now.getMonth() + 1).padStart(2, '0')
    const d = String(now.getDate()).padStart(2, '0')
    const hh = String(now.getHours()).padStart(2, '0')
    const mm = String(now.getMinutes()).padStart(2, '0')
    return `${y}-${m}-${d} ${hh}:${mm}`
  }

  private getDefaultSummary(): string {
    return '专注如焚香，心静事成。愿君日日精进，学业有成。'
  }
}

export const aiManager = new AIManager()

import { Controller } from "@hotwired/stimulus"

// Auto-refresh dashboard data at regular intervals
export default class extends Controller {
  static values = {
    interval: { type: Number, default: 300000 }, // 5 minutes
    url: String
  }

  connect() {
    if (this.hasUrlValue) {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.timer = setInterval(() => this.refresh(), this.intervalValue)
  }

  stopPolling() {
    if (this.timer) {
      clearInterval(this.timer)
    }
  }

  async refresh() {
    try {
      const response = await fetch(this.urlValue, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })
      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.warn("Auto-refresh failed:", error)
    }
  }
}

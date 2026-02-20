import { Controller } from "@hotwired/stimulus"

// Handles delete confirmations with a native dialog
export default class extends Controller {
  static values = { message: { type: String, default: "Are you sure?" } }

  confirm(event) {
    if (!window.confirm(this.messageValue)) {
      event.preventDefault()
      event.stopImmediatePropagation()
    }
  }
}

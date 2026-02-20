import { Controller } from "@hotwired/stimulus"

// Toggles sort direction on table columns
export default class extends Controller {
  static targets = ["header", "body"]
  static values = { column: String, direction: { type: String, default: "asc" } }

  sort(event) {
    const column = event.currentTarget.dataset.column
    const rows = Array.from(this.bodyTarget.querySelectorAll("tr"))

    if (this.columnValue === column) {
      this.directionValue = this.directionValue === "asc" ? "desc" : "asc"
    } else {
      this.columnValue = column
      this.directionValue = "asc"
    }

    const index = parseInt(event.currentTarget.dataset.index)
    const dir = this.directionValue === "asc" ? 1 : -1

    rows.sort((a, b) => {
      const aVal = a.cells[index]?.textContent.trim() || ""
      const bVal = b.cells[index]?.textContent.trim() || ""
      const aNum = parseFloat(aVal.replace(/[R$%,\s]/g, ""))
      const bNum = parseFloat(bVal.replace(/[R$%,\s]/g, ""))

      if (!isNaN(aNum) && !isNaN(bNum)) return (aNum - bNum) * dir
      return aVal.localeCompare(bVal) * dir
    })

    rows.forEach(row => this.bodyTarget.appendChild(row))

    // Update sort indicators
    this.headerTargets.forEach(h => {
      h.querySelector(".sort-indicator")?.remove()
    })
    const indicator = document.createElement("span")
    indicator.className = "sort-indicator ml-1 text-emerald-400"
    indicator.textContent = this.directionValue === "asc" ? "↑" : "↓"
    event.currentTarget.appendChild(indicator)
  }
}

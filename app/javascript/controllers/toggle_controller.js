import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    console.log("Toggle controller connected")
  }

  toggle() {
    this.menuTarget.classList.toggle("open")
    this.buttonTarget.textContent = 
      this.menuTarget.classList.contains("open") ? "Close" : "≡"
  }
}
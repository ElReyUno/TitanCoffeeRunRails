// Stimulus Controllers for Interactivity
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count", "items", "total"]
  static values = { items: Array }

  connect() {
    this.loadCart()
  }

  add(event) {
    event.preventDefault()
    const form = event.target
    const formData = new FormData(form)
    
    fetch('/api/v1/cart_items', {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.updateCart(data.cart)
        this.showNotification('Item added to cart!')
      }
    })
  }

  updateCart(cartData) {
    this.itemsValue = cartData.items
    this.countTarget.textContent = cartData.total_items
    this.totalTarget.textContent = `$${cartData.total_amount}`
    this.renderCartItems()
  }

  renderCartItems() {
    // Implementation for rendering cart items
  }

  showNotification(message) {
    // Implementation for showing notifications
  }
}
// This script allows the user to select coffee items, update a cart, and uses
// web storage to store the items they select.
document.addEventListener('DOMContentLoaded', function () {
  class Product {
    constructor(name, price) {
      this.name = name;
      this.price = price;
    }
  }

  class Order {
    constructor(date, product, size, quantity, notes) {
      this.date = date;
      this.product = product;
      this.size = size;
      this.quantity = quantity;
      this.notes = notes;
    }
  }

  const products = [
    new Product('Cappuccino', 9),
    new Product('Macaroons', 4),
    new Product('Donuts', 5)
  ];

  function createOrder(productIndex, size, quantity, notes) {
    const product = products[productIndex];
    return new Order(new Date(), product, size, quantity, notes);
  }

  function clearCart() {
    localStorage.removeItem('cart');
  }

  const orderForm = document.getElementById('orderForm');
  orderForm.addEventListener('submit', function (event) {
    event.preventDefault();
    clearCart(); // Clear the cart before adding new items

    const formData = new FormData(orderForm);
    const specialNotes = formData.get('specialNotes') || '';
    const donateTitan = formData.get('donateTitanHidden') === 'true';
    const cart = [];

    products.forEach((product, index) => {
      const size = formData.get(`${product.name.toLowerCase().replace(' ', '')}Size`);
      const quantity = parseInt(formData.get(`${product.name.toLowerCase().replace(' ', '')}Quantity`), 10);
      const notes = formData.get(`${product.name.toLowerCase().replace(' ', '')}`) || specialNotes;

      if (size && quantity > 0) {
        const order = createOrder(index, size, quantity, notes);
        cart.push(order);
      }
    });

    if (donateTitan) {
      cart.push({ product: { name: 'Donation', price: 2 }, size: '', quantity: 1, notes: '' });
    }

    localStorage.setItem('cart', JSON.stringify(cart));
    window.location.href = 'checkout.html';
  });

  const orderTableBody = document.querySelector('#orderTable tbody');
  const totalAmountDiv = document.getElementById('totalAmount');
  const confirmOrderButton = document.getElementById('confirmOrder');
  const cancelOrderButton = document.getElementById('cancelOrder');
  const donateCheckbox = document.getElementById('donateTitan');

  function loadOrderSummary() {
    let cart = JSON.parse(localStorage.getItem('cart')) || [];
    orderTableBody.innerHTML = '';
    let totalAmount = 0;
    cart.forEach(order => {
      const row = document.createElement('tr');
      const price = order.product.price * order.quantity;
      totalAmount += price;
      row.innerHTML = `
        <td>${order.product.name}</td>
        <td>${order.size}</td>
        <td>${order.quantity}</td>
        <td>$${price.toFixed(2)}</td>
        <td>${order.notes}</td>
      `;
      orderTableBody.appendChild(row);
    });

    // Add donation if checkbox is checked
    if (donateCheckbox && donateCheckbox.checked) {
      totalAmount += 2;
    }

    totalAmountDiv.innerHTML = `<h3>Total Amount: $${totalAmount.toFixed(2)}</h3>`;
  }

  confirmOrderButton.addEventListener('click', function () {
    alert('Order confirmed!');
    localStorage.removeItem('cart');
    window.location.href = 'index.html';
  });

  cancelOrderButton.addEventListener('click', function () {
    alert('Order canceled.');
    localStorage.removeItem('cart');
    window.location.href = 'menu.html';
  });

  loadOrderSummary();
});
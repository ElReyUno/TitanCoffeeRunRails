// This script implements a checkout page that displays the items they ordered and
// displays the total needed to be paid.
document.addEventListener('DOMContentLoaded', function () {
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
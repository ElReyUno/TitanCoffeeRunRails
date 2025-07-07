document.addEventListener('DOMContentLoaded', async (event) => {
   const ctx = document.getElementById('salesChart').getContext('2d');

   try {
      // Fetch data from the new API endpoint
      const response = await fetch('http://localhost:3000/orders');
      const data = await response.json();

      // Log the entire response to inspect its structure
      console.log('Fetched data:', data);

      // Check if data is defined and is an array
      if (!Array.isArray(data)) {
         throw new Error('Fetched data is not an array');
      }

      // Process data to get sales data for each quarter
      const salesData = [0, 0, 0, 0]; // Initialize sales data for each quarter

      data.forEach(order => {
         const date = new Date(order.date);
         const month = date.getMonth(); // Get month (0-11)
         const quarter = Math.floor(month / 3); // Determine the quarter (0-3)
         const totalPrice = order.product.price * order.product.quantity;
         salesData[quarter] += totalPrice; // Add total price to the respective quarter
      });

      const salesChart = new Chart(ctx, {
         type: 'bar',
         data: {
            labels: ['Jan-Mar', 'Apr-Jun', 'Jul-Sep', 'Oct-Dec'],
            datasets: [{
               label: 'Sales',
               data: salesData,
               backgroundColor: [
                  'rgba(75, 192, 192, 0.2)', // Jan-Mar
                  'rgba(0, 128, 0, 0.2)',    // Apr-Jun
                  'rgba(255, 215, 0, 0.2)',  // Jul-Sep
                  'rgba(225, 69, 14, 0.2)'   // Oct-Dec
               ],
               borderColor: [
                  'rgba(75, 192, 192, 1)',   // Jan-Mar
                  'rgba(0, 128, 0, 1)',      // Apr-Jun
                  'rgba(255, 215, 0, 1)',    // Jul-Sep
                  'rgba(225, 69, 14, 1)'     // Oct-Dec
               ],
               borderWidth: 1
            }]
         },
         options: {
            scales: {
               y: {
                  beginAtZero: true
               }
            },
            plugins: {
               legend: {
                  display: false
               }
            }
         }
      });

      document.getElementById('resetPasswordButton').addEventListener('click', () => {
         salesChart.data.datasets[0].data = [0, 0, 0, 0];
         salesChart.update();
      });
      
   } catch (error) {
      console.error('Error fetching or processing data:', error);
   }
});

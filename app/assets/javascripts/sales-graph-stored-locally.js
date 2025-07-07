document.addEventListener('DOMContentLoaded', (event) => {
   const ctx = document.getElementById('salesChart').getContext('2d');
   const salesChart = new Chart(ctx, {
      type: 'bar',
      data: {
         labels: ['Jan-Mar', 'Apr-Jun', 'Jul-Sep', 'Oct-Dec'],
         datasets: [{
            label: 'Sales Data',
            data: [2005.00, 1471.31, 892.86, 531.60],
            backgroundColor: [
               'rgba(75, 192, 192, 0.2)', // Jan - Mar
               'rgba(0, 128, 0, 0.2)',    // Arp - Jun
               'rgba(255, 215, 0, 0.2)',  // Jul - Sep
               'rgba(225, 69, 14, 0.2)'   // Oct - Dec
            ],
            borderColor: [
               'rgba(75, 192, 192, 1)',   // Jan - Mar
               'rgba(0, 128, 0, 1)',      // Arp - Jun
               'rgba(255, 215, 0, 1)',    // Jul - Sep
               'rgba(225, 69, 14, 1)'     // Oct - Dec
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
});
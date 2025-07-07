// This script adds the $2 Titan Donation to the checkout cart
function updateDonateTitanHidden() {
   const donateCheckbox = document.getElementById('donateTitan');
   const donateHidden = document.getElementById('donateTitanHidden');
   donateHidden.value = donateCheckbox.checked ? 'true' : 'false';
 }
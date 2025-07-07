// Accessible Toggling Menu Button (For Smaller Screens)
function toggleMenu() {
  const navigation = document.querySelector('nav ul');
  const toggleButton = document.getElementById('toggleMenu');
  
  if (navigation && toggleButton) {
    navigation.classList.toggle('open');
    toggleButton.textContent = navigation.classList.contains('open') ? 'Close' : '≡';
  }
}

// Also set up event listener for accessibility
const toggleMenuBtn = document.getElementById('toggleMenu');
const navigation = document.querySelector('nav ul');

if (toggleMenuBtn && navigation) {
  toggleMenuBtn.addEventListener('click', toggleMenu);
} else {
  console.error('Error: Could not find the menu button or navigation element.');
}

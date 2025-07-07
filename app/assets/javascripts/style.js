// Accessible Toggling Menu Button (For Smaller Screens) - Adapted from original
const toggleMenuButton = document.getElementById('toggleMenu');
const navigation = document.querySelector('nav ul');

if (toggleMenuButton && navigation) {
  toggleMenuButton.addEventListener('click', () => {
    navigation.classList.toggle('open');
    toggleMenuButton.textContent = navigation.classList.contains('open') ? 'Close' : '≡';
  });
} else {
  console.error('Error: Could not find the menu button or navigation element.');
}

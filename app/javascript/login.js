document.addEventListener('DOMContentLoaded', function () {
   const form = document.querySelector('.form-container');
   const accountUserNameInput = document.getElementById('loginUserName');
   const loginPasswordInput = document.getElementById('loginPassword');
   const loginButton = document.getElementById('loginButton');
   const resetPasswordButton = document.getElementById('resetPasswordButton');
   const menuPagePath = './menu.html'; // Define the path to menu.html
   const salesPagePath = './sales.html'; // Define the path to sales.html
   const resetPasswordPath = './reset-password.html'; // Define the path to reset-password.html

   function displayError(inputField, message) {
      const errorElement = document.createElement('span');
      errorElement.classList.add('error-message');
      errorElement.textContent = message;

      inputField.parentElement.insertBefore(errorElement, inputField.nextSibling);
   }

   function clearErrors() {
      const errorElements = document.querySelectorAll('.error-message');
      errorElements.forEach(errorElement => errorElement.remove());

      const inputFields = document.querySelectorAll('.input-error');
      inputFields.forEach(inputField => inputField.classList.remove('input-error'));
   }

   function validateForm() {
      clearErrors();

      const formData = {
         Email: accountUserNameInput.value.trim(),
         Password: loginPasswordInput.value.trim()
      };

      let isValid = true;

      const users = JSON.parse(localStorage.getItem('users')) || [];
      const user = users.find(user => user.email.toLowerCase() === formData.Email.toLowerCase());

      if (formData.Email === '') {
         displayError(accountUserNameInput, 'This field is required.');
         isValid = false;
      } else if (!user && formData.Email.toLowerCase() !== 'admin') {
         displayError(accountUserNameInput, 'Username not on file.');
         isValid = false;
      }

      if (formData.Password === '') {
         displayError(loginPasswordInput, 'This field is required.');
         isValid = false;
      } else if (user && formData.Password !== user.password && formData.Email.toLowerCase() !== 'admin') {
         displayError(loginPasswordInput, 'Incorrect password.');
         isValid = false;
      }

      if (isValid) {
         if (formData.Email.toLowerCase() === 'admin' && formData.Password === 'test123') {
            window.location.href = salesPagePath; // Redirect to sales.html if admin credentials are correct
         } else {
            window.location.href = menuPagePath; // Redirect to menu.html if valid
         }
      }

      return isValid;
   }

   loginButton.addEventListener('click', (event) => {
      event.preventDefault();
      validateForm();
   });

   resetPasswordButton.addEventListener('click', (event) => {
      event.preventDefault();
      window.location.href = resetPasswordPath; // Redirect to reset-password.html
   });
});
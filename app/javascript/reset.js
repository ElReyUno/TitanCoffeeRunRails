// LATER COME BACK AND MODUALRIZE CODE
document.addEventListener('DOMContentLoaded', function () {
   const localUserNameInput = document.getElementById('resetUserName');
   const newPassword = document.getElementById('resetPassword');
   const resetButton = document.getElementById('resetPasswordButton');
   const loginPagePath = './login.html'; // Define the path to login.html

   function displayError(inputField, message) {
      const errorElement = document.createElement('span');
      errorElement.classList.add('error-message');
      errorElement.textContent = message;
      inputField.classList.add('input-error');
      inputField.parentElement.insertBefore(errorElement, inputField.nextSibling);
   }

   function clearErrors() {
      const errorElements = document.querySelectorAll('.error-message');
      errorElements.forEach(errorElement => errorElement.remove());

      const inputFields = document.querySelectorAll('.input-error');
      inputFields.forEach(inputField => inputField.classList.remove('input-error'));
   }

   function validateForm() {
      clearErrors(); // Clear previous errors before validation

      // COULD POSSIBLY BE REMOVED
      const formData = {
         UserName: localUserNameInput.value.trim(),
         Password: newPassword.value.trim()
      };

      let isValid = true;

      if (formData.UserName === '') {
         displayError(localUserNameInput, 'This field is required.');
         isValid = false;
      }

      if (formData.Password === '') {
         displayError(newPassword, 'Please enter new password.');
         isValid = false;
      }

      if (!isValid) {
         return false;
      }

      let users = JSON.parse(localStorage.getItem('users')) || [];
      const userIndex = users.findIndex(user => user.email.toLowerCase() === formData.UserName.toLowerCase());

      if (userIndex === -1) {
         displayError(localUserNameInput, 'Username not found. Please try again.');
         return false;
      }

      users[userIndex].password = formData.Password;
      localStorage.setItem('users', JSON.stringify(users));
      window.location.href = loginPagePath; // If valid redirect to login.html

      return true;
   }

   function clearErrorOnInput(event) {
      const inputField = event.target;
      const errorElement = inputField.parentElement.querySelector('.error-message');
      if (errorElement) {
         errorElement.remove();
      }
      inputField.classList.remove('input-error');
   }

   localUserNameInput.addEventListener('input', clearErrorOnInput);
   newPassword.addEventListener('input', clearErrorOnInput);

   resetButton.addEventListener('click', (event) => {
      event.preventDefault();
      validateForm();
   });
});

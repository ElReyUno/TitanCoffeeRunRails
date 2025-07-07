// This script allows the user to click and fill out a form to register for an account
// and log into the application, and start using the applications to place orders.
document.addEventListener('DOMContentLoaded', function () {
   const form = document.querySelector('.form-container');
   const accountEmailInput = document.getElementById('accountEmail');
   const passwordInput = document.getElementById('accountPassword');
   const confirmPasswordInput = document.getElementById('confirmAccountPassword');
   const applyForAccountButton = document.getElementById('applyForAccountButton');
   const resetPasswordButton = document.getElementById('resetPasswordButton');
   const accountResultsTable = document.getElementById('accountResultsTable');
   const accountResultsContainer = document.getElementById('accountResultsContainer');

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

   function storeFormData(formData) {
      // Retrieve existing users from local storage
      let users = JSON.parse(localStorage.getItem('users')) || [];

      // Check if the email already exists
      const userExists = users.some(user => user.email.toLowerCase() === formData.Email.toLowerCase());

      if (userExists) {
         displayError(accountEmailInput, 'Username already exists.');
         return false;
      }

      // Add new user data
      users.push({
         email: formData.Email,
         password: formData.Password
      });

      // Store updated users array back to local storage
      localStorage.setItem('users', JSON.stringify(users));
      return true;
   }

   function displayStoredData() {
      const email = accountEmailInput.value.trim();
      const users = JSON.parse(localStorage.getItem('users')) || [];
      const user = users.find(user => user.email === email);

      if (user) {
         accountResultsTable.querySelector('tbody').innerHTML = '';

         const emailRow = accountResultsTable.insertRow();
         const emailFieldCell = emailRow.insertCell();
         const emailValueCell = emailRow.insertCell();
         emailFieldCell.textContent = 'Email';
         emailValueCell.textContent = user.email;

         const passwordRow = accountResultsTable.insertRow();
         const passwordFieldCell = passwordRow.insertCell();
         const passwordValueCell = passwordRow.insertCell();
         passwordFieldCell.textContent = 'Password';
         passwordValueCell.textContent = user.password;

         accountResultsTable.style.display = 'table';
         accountResultsContainer.style.display = 'block';
      } else {
         alert('No data found in local storage for this email.');
      }
   }

   function validateForm() {
      clearErrors();

      accountResultsTable.querySelector('tbody').innerHTML = '';

      const formData = {
         Email: accountEmailInput.value.trim(),
         Password: passwordInput.value.trim(),
         Confirm_Password: confirmPasswordInput.value.trim()
      };

      let isValid = true;

      if (formData.Email === '') {
         displayError(accountEmailInput, 'This field is required.');
         isValid = false;
      }
      if (formData.Password === '') {
         displayError(passwordInput, 'This field is required.');
         isValid = false;
      }
      if (formData.Confirm_Password === '') {
         displayError(confirmPasswordInput, 'This field is required.');
         isValid = false;
      } else if (formData.Password !== formData.Confirm_Password) {
         displayError(confirmPasswordInput, 'This entry must equal the first entry.');
         isValid = false;
      }

      if (!isValid) {
         const tableBody = accountResultsTable.querySelector('tbody');
         for (const field in formData) {
            const row = tableBody.insertRow();
            const fieldCell = row.insertCell();
            const valueCell = row.insertCell();

            fieldCell.textContent = field;

            if (formData[field] === '' || (field === 'reEnterPassword' && (formData.password !== formData.reEnterPassword || formData.password === ''))) {
               valueCell.textContent = 'Invalid Entry';
               valueCell.classList.add('error');
            } else {
               valueCell.textContent = formData[field];
            }
         }

         accountResultsTable.style.display = 'table';
         accountResultsContainer.style.display = 'block';
      } else {
         if (storeFormData(formData)) { // Only redirect if storing data was successful
            accountResultsTable.style.display = 'none';
            accountResultsContainer.style.display = 'none';
            window.location.href = 'login.html'; // Redirect to login.html if valid
         }
      }

      return isValid;
   }

   applyForAccountButton.addEventListener('click', (event) => {
      event.preventDefault();
      validateForm();
   });

   form.addEventListener('submit', (event) => {
      event.preventDefault();
      validateForm();
   });
});
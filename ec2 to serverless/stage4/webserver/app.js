// Check the path, route based on location.
function displayUsername() {
    let id_token = window.sessionStorage.getItem('id_token');
    if (id_token) {
        let payload = parseJwt(id_token);
        let username = payload['cognito:username'];
        document.getElementById('displayUsername').textContent = `Welcome, ${username}`;
        return username;
    }
    
}
  
window.onload = function() {
    
    if (window.location.pathname.endsWith('register.html')) {
        document.getElementById('registerForm').addEventListener('submit', function(event) {
            event.preventDefault();

            var username = document.getElementById('username').value;
            var password = document.getElementById('password').value;

            var formData = {
                username: username,
                password: password
            };

            app_register(formData);
        });
    } else if (window.location.pathname.endsWith('login.html')) {
        document.getElementById('loginForm').addEventListener('submit', function(event) {
            console.log('Form submission event listener called.');
            event.preventDefault();

            var username = document.getElementById('username').value;
            var password = document.getElementById('password').value;

            var formData = {
                username: username,
                password: password
            };

            app_login(formData);
        });
    } else if (window.location.pathname.endsWith('submit_fortune.html')) {
        document.getElementById('submitFortuneForm').addEventListener('submit', function(event) {
            event.preventDefault();

            var fortune = document.getElementById('fortune').value;

            var formData = {
                fortune: fortune,
                username: displayUsername()
            };

            submit_fortune(formData);
            
        });
    } else if (window.location.pathname.endsWith('random_fortune.html')) {
        document.getElementById('getFortuneButton').addEventListener('click', function(event) {
            event.preventDefault();

            retrieve_fortune();
            ;
        });
    } else if (window.location.pathname.endsWith('logout.html')) {
        document.getElementById('logoutButton').addEventListener('click', function(event) {
            event.preventDefault();
            app_logout();
        });
    }
    if (window.location.pathname.endsWith('index.html') ||
        window.location.pathname.endsWith('submit_fortune.html') ||
        window.location.pathname.endsWith('random_fortune.html')) {
        displayUsername();
    }

}

function app_register(formData) {
    fetch('<API_ENDPOINT>/register', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(formData)
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) { // Assuming the server returns a success field in the response
            document.getElementById('resultMessage').textContent = 'Registration success!';
        } else {
            document.getElementById('resultMessage').textContent = 'Registration failed.';
        }
    })
    .catch((error) => {
        console.error('Error:', error);
        document.getElementById('resultMessage').textContent = `An error occurred: ${error.message}`;
    });
}
// Fetch the user's information from Cognito
// Function to parse a JWT token
function parseJwt(token) {
    var base64Url = token.split('.')[1];
    var base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    var jsonPayload = decodeURIComponent(atob(base64).split('').map(function(c) {
        return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
    }).join(''));

    return JSON.parse(jsonPayload);
}

// Function to fetch and display the username

function app_login(formData) {
    console.log("Preparing to send login request with form data:", formData);
  
    let fetchOptions = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(formData)
    };
  
    console.log("Fetch options for login request:", fetchOptions);
  
    fetch('<API_ENDPOINT>/login', fetchOptions)
      .then(response => {
        console.log('Server response:', response);
        if (!response.ok) {
          throw new Error('HTTP status ' + response.status);
        }
        return response.json();
      })
      .then(data => {
        console.log('Server data:', data);
        if (data.message === 'User logged in successfully') { 
            let id_token = data.id_token; // extract id_token from server response data
            let access_token = data.access_token;
            sessionStorage.setItem('id_token', id_token);
            sessionStorage.setItem('access_token', access_token);
            document.getElementById('loginResultMessage').textContent = 'Login success!';
            window.location.href = 'index.html'; 
        } else {
            document.getElementById('loginResultMessage').textContent = 'Login failed.';
        }
    })
    
      .catch((error) => {
        console.error('Error:', error);
        document.getElementById('loginResultMessage').textContent = `An error occurred: ${error.message}`;
      });
  }
  


function submit_fortune(formData) {
    let id_token = window.sessionStorage.getItem('id_token');
    fetch('<API_ENDPOINT>/submit', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': id_token  
        },
        body: JSON.stringify(formData)
    })
    .then(response => response.text())  // Use response.text() instead of response.json()
    .then(responseBody => {
        if (responseBody.includes("Submission Success!")) {
            document.getElementById('submitFortuneResultMessage').textContent = 'Fortune submitted successfully!';
        } else {
            document.getElementById('submitFortuneResultMessage').textContent = `An error occurred: ${responseBody}`;
        }
    })

    .catch((error) => {
        console.error('Error:', error);
        document.getElementById('submitFortuneResultMessage').textContent = `An error occurred: ${error.message}`;
    });
}

function retrieve_fortune() {
    let id_token = window.sessionStorage.getItem('id_token');
    fetch('<API_ENDPOINT>/retrieve', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': id_token
        }
    })
    .then(response => response.text())  // Use response.text() instead of response.json()
    .then(responseBody => {
        document.getElementById('fortuneDisplay').textContent = responseBody;
    })
    .catch((error) => {
        console.error('Error:', error);
        document.getElementById('fortuneDisplay').textContent = `An error occurred: ${error.message}`;
    });
}



function app_logout() {
    let access_token = window.sessionStorage.getItem('access_token');
    let id_token = window.sessionStorage.getItem('id_token');

    // Call logout API endpoint
    fetch('<API_ENDPOINT>/logout', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': id_token 
        },
        body: JSON.stringify({access_token})
    })
    .then(response => response.json())
    .then(data => {
        if (data.message === 'User logged out successfully') {
            window.sessionStorage.removeItem('id_token');
            window.sessionStorage.removeItem('access_token');
            window.location.href = 'index.html'; // redirect to home page after logout
        } else {
            // Handle logout error
            console.error('Logout error:', data.message);
        }
    })
    .catch((error) => {
        console.error('Error:', error);
    });
}

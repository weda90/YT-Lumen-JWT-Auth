# 🚀 Tutorial: Lumen - JWT Authentication with SQLite

![PHP](https://img.shields.io/badge/PHP-8.x-blue)
![Lumen](https://img.shields.io/badge/Lumen-Framework-red)
![JWT](https://img.shields.io/badge/Auth-JWT-orange)
![Docker](https://img.shields.io/badge/Docker-DevContainer-blue)


This guide provides a **step-by-step implementation of JWT Authentication in Lumen**, using a SQLite database.

[![Lumen JWT Auth - without Talk](https://img.youtube.com/vi/1TEej4vlagM/maxresdefault.jpg)](https://www.youtube.com/watch?v=1TEej4vlagM)

🎥 **Watch the full video:**  
https://www.youtube.com/watch?v=1TEej4vlagM


---

## 🛠️ Step 1: Environment Setup

This step focuses on preparing an isolated development environment using Docker.

### 1. Create Project Directory

```bash
mkdir lumen_jwt_auth
cd lumen_jwt_auth
```

---

### 2. Create a Lumen Project Using Composer Container

Composer does not need to be installed on the host machine.

```bash
composer create-project --prefer-dist laravel/lumen .
```

Run the built-in PHP server:

```bash
php -S 0.0.0.0:8000 -t public
```

---

### (Optional) Recommended VS Code Extensions

```json
"humao.rest-client",
"bmewburn.vscode-intelephense-client",
"amiralizadeh9480.laravel-extra-intellisense"
```

---

## 🏗️ Step 2: Preparation & Configuration

### 1. Install JWT Package

Lumen requires the `tymon/jwt-auth` package. Make sure to install the compatible version.

```bash
composer require tymon/jwt-auth
```

---

### 2. Register Service Provider & Configuration

#### A. Register JWT Service Provider

Edit `bootstrap/app.php` and add the following:

```php
// bootstrap/app.php

$app->register(Tymon\JWTAuth\Providers\LumenServiceProvider::class);

$app->withFacades();
$app->withEloquent();
```

---

#### B. Generate JWT Secret Key

Generate a secret key for JWT:

```bash
php artisan jwt:secret
```

This will add `JWT_SECRET` to your `.env` file.

---

## 🗄️ Step 3: Database Setup (SQLite)

### A. Create SQLite Database File

```bash
touch database/database.sqlite
```

---

### B. Configure `.env`

Update database configuration:

```env
DB_CONNECTION=sqlite
# DB_DATABASE=/var/www/html/database/database.sqlite (optional if default path is correct)
```

---

## 📦 Step 4: Migration & Database Schema

### A. Create Migration File

```bash
php artisan make:migration create_users_table
```

---

### B. Edit Migration File

`database/migrations/xxxx_create_users_table.php`

```php
public function up()
{
    Schema::create('users', function (Blueprint $table) {
        $table->id();
        $table->string('name');
        $table->string('email')->unique();
        $table->string('password');
        $table->timestamps();
    });
}
```

---

### C. Run Migration

```bash
php artisan migrate
```

---

## 👤 Step 5: User Model Configuration

The `User` model must implement `JWTSubject` so JWT can identify users properly.

Edit `app/Models/User.php`:

```php
namespace App\Models;

use Illuminate\Auth\Authenticatable;
use Laravel\Lumen\Auth\Authorizable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Contracts\Auth\Authenticatable as AuthenticatableContract;
use Illuminate\Contracts\Auth\Access\Authorizable as AuthorizableContract;
use Tymon\JWTAuth\Contracts\JWTSubject;

class User extends Model implements AuthenticatableContract, AuthorizableContract, JWTSubject
{
    use Authenticatable, Authorizable;

    protected $fillable = ['name', 'email', 'password'];
    protected $hidden = ['password'];

    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    public function getJWTCustomClaims()
    {
        return [];
    }
}
```

---

## 🔐 Step 6: Auth Guard Configuration

### 1. Create Config Folder

```bash
mkdir config
```

---

### 2. Copy Auth Config from Vendor

```bash
cp vendor/laravel/lumen-framework/config/auth.php config/auth.php
```

---

### 3. Update `config/auth.php`

Modify the default guard to use JWT:

```php
'defaults' => [
    'guard' => 'api',
    'passwords' => 'users',
],

'guards' => [
    'api' => [
        'driver' => 'jwt',
        'provider' => 'users',
    ],
],

'providers' => [
    'users' => [
        'driver' => 'eloquent',
        'model'  => App\Models\User::class,
    ],
],
```

---

### 4. Load Auth Configuration in Lumen

Edit `bootstrap/app.php`:

```php
$app = new Laravel\Lumen\Application(
    realpath(__DIR__.'/../')
);

$app->configure('auth');

$app->routeMiddleware([
    'auth' => App\Http\Middleware\Authenticate::class,
]);

$app->register(App\Providers\AuthServiceProvider::class);
$app->register(Tymon\JWTAuth\Providers\LumenServiceProvider::class);
```

---

## 🔑 Step 7: Core Authentication Implementation

### 1. Create Auth Controller

Create `app/Http/Controllers/AuthController.php`:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $this->validate($request, [
            'name' => 'required|string',
            'email' => 'required|email|unique:users',
            'password' => 'required|confirmed|min:6',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);

        return response()->json([
            'message' => 'User successfully registered',
            'user' => $user
        ], 201);
    }

    public function login(Request $request)
    {
        $credentials = $request->only(['email', 'password']);

        if (! $token = Auth::attempt($credentials)) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        return $this->respondWithToken($token);
    }

    public function me()
    {
        return response()->json(Auth::user());
    }

    public function refresh()
    {
        return $this->respondWithToken(Auth::refresh());
    }

    public function logout()
    {
        Auth::logout();
        return response()->json(['message' => 'Successfully logged out']);
    }

    protected function respondWithToken($token)
    {
        return response()->json([
            'access_token' => $token,
            'token_type' => 'bearer',
            'user' => Auth::user(),
            'expires_in' => Auth::factory()->getTTL() * 60
        ]);
    }
}
```

---

## 🌐 Step 8: API Routes Configuration

Edit `routes/web.php`:

```php
$router->group(['prefix' => 'api'], function () use ($router) {

    // Public routes
    $router->post('register', 'AuthController@register');
    $router->post('login', 'AuthController@login');

    // Protected routes
    $router->group(['middleware' => 'auth'], function () use ($router) {
        $router->get('me', 'AuthController@me');
        $router->post('refresh', 'AuthController@refresh');
        $router->post('logout', 'AuthController@logout');
    });
});
```

---

## 🧪 Step 9: API Testing with REST Client

Create `test.http`:

```http
@baseUrl = http://localhost:8000/api
@contentType = application/json

### Register
POST {{baseUrl}}/register
Content-Type: {{contentType}}

{
  "name": "Your_name",
  "email": "your_email@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}

### Login
# @name login
POST {{baseUrl}}/login
Content-Type: {{contentType}}

{
  "email": "your_email@example.com",
  "password": "password123"
}

@authToken = {{login.response.body.access_token}}

### Profile
GET {{baseUrl}}/me
Authorization: Bearer {{authToken}}

### Refresh Token
POST {{baseUrl}}/refresh
Authorization: Bearer {{authToken}}

### Logout
POST {{baseUrl}}/logout
Authorization: Bearer {{authToken}}
```

---

## ✅ Key Notes

* `Auth::attempt()` automatically validates credentials and password hash.
* Protected routes require `Authorization: Bearer <token>`.
* Default JWT expiration is **60 minutes** (configurable in `config/jwt.php`).

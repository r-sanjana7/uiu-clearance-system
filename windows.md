# Setup Guide — UIU Clearance System on Windows

A step-by-step guide to get this PHP + MySQL project running on a Windows machine. Tested on **Windows 10** and **Windows 11** with **PHP 8.3** and **MySQL 8**.

> **Time required:** ~20–30 minutes on a clean machine.

---

## 1. Prerequisites

You need four things installed on Windows:

1. **PHP 8.x** (with the MySQL driver)
2. **MySQL Server 8**
3. A text editor (VS Code, Notepad++, or any)
4. *(Optional but recommended)* **Git for Windows** — only if you want to clone the repo

### 1.1 Install PHP

The simplest way on Windows is to use a pre-built PHP package.

**Option A — Official Windows PHP build (recommended):**

1. Go to <https://windows.php.net/download/>
2. Download the **VS16 x64 Non Thread Safe** zip (e.g. `php-8.3.x-nts-Win32-vs16-x64.zip`)
3. Extract it to a folder **without spaces in the path**, e.g. `C:\php\`
4. Add `C:\php` to your system `PATH`:
   - Press `Win` → search "Edit the system environment variables" → click it
   - Click **Environment Variables…**
   - Under "System variables", find `Path`, click **Edit…**
   - Click **New**, type `C:\php`, click OK
   - Click OK on the other dialogs
5. Open a **new** PowerShell window and verify:

```powershell
php -v
# Should print "PHP 8.3.x (cli) ..."
```

**Option B — XAMPP / WAMP / Laragon:**

If you prefer an all-in-one package, install one of:
- **XAMPP** — <https://www.apachefriends.org/>
- **WampServer** — <https://www.wampserver.com/>
- **Laragon** — <https://laragon.org/>

These bundle PHP, MySQL (or MariaDB), and a control panel. Skip to **Step 2** if you used one of these — the MySQL step is already handled.

### 1.2 Enable the MySQL + fileinfo PHP extensions

PHP for Windows ships with the extensions, you just have to uncomment them.

1. In your PHP folder (e.g. `C:\php\`), find `php.ini-development`
2. Copy it and rename the copy to `php.ini`
3. Open `php.ini` in a text editor
4. Find and uncomment these lines (remove the leading `;`):

```ini
extension=mysqli
extension=pdo_mysql
extension=fileinfo
```

5. Save the file
6. Verify in a new PowerShell window:

```powershell
php -m | Select-String -Pattern "pdo_mysql|fileinfo"
# Should list both extensions
```

### 1.3 Install MySQL Server 8

**Option A — MySQL Installer (recommended):**

1. Go to <https://dev.mysql.com/downloads/installer/>
2. Download the **Windows (x86, 32-bit) MSI Installer** (it installs both 32 and 64-bit, despite the name)
3. Run the installer
4. Choose **Custom** setup
5. Select **MySQL Server 8.x** (and optionally MySQL Workbench)
6. Click Next → Execute → wait for the install to finish
7. When asked, set a **root password** and remember it

**Option B — MariaDB (drop-in alternative):**

If `mysql-server` is hard to get on your machine, install **MariaDB 10.x** from <https://mariadb.org/download/>. The rest of this guide works the same way.

---

## 2. Copy the project

Place the project folder anywhere you like. This guide assumes:

```
C:\projects\UIU_Clearence\
```

You can rename the folder — it does not affect anything.

> **Avoid spaces in the path** if possible. PHP on Windows can behave oddly when the project path contains `Program Files` or `My Documents`.

---

## 3. Create the database and the dedicated app user

1. Open a **new** PowerShell window **as Administrator** (right-click PowerShell → "Run as administrator")
2. Run the bundled SQL script:

```powershell
cd C:\projects\UIU_Clearence
Get-Content backend\sql\01-create-db.sql | mysql -u root -p
# Enter the root password you set in Step 1.3
```

This creates the `uiu_clearance` database and a MySQL user `uiu_app` with password `devpass`.

> **Note:** The shipped `01-create-db.sql` sets the app user's password to `devpass`. You can change it in that file before running — just make sure the matching value lands in `.env` (next step).

> **Trouble?** If `mysql` is not recognized, add the MySQL `bin` directory to your `PATH`. It's usually `C:\Program Files\MySQL\MySQL Server 8.0\bin\`. See Step 1.1.4 for how to edit `PATH`.

---

## 4. Create the `.env` file

PHP reads the DB credentials from environment variables.

1. Open PowerShell in the project root:

```powershell
cd C:\projects\UIU_Clearence
Copy-Item .env.example .env
notepad .env
```

2. Edit the file so it matches your setup. The defaults work out of the box if you used the shipped `01-create-db.sql`:

```
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=uiu_clearance
DB_USER=uiu_app
DB_PASS=devpass
DB_CHARSET=utf8mb4
UPLOAD_MAX_MB=100
```

3. Save and close Notepad.

> **PowerShell note:** PowerShell does **not** auto-load `.env` files. The app uses `getenv()` to read the system environment, not the file. Either:
> - **Easiest:** leave the defaults hard-coded in `backend\config\db.php` (they match `.env.example`).
> - **Better:** set them as **Windows user environment variables** so PHP picks them up:
>   ```powershell
>   [System.Environment]::SetEnvironmentVariable("DB_HOST", "127.0.0.1", "User")
>   [System.Environment]::SetEnvironmentVariable("DB_NAME", "uiu_clearance", "User")
>   [System.Environment]::SetEnvironmentVariable("DB_USER", "uiu_app", "User")
>   [System.Environment]::SetEnvironmentVariable("DB_PASS", "devpass", "User")
>   ```
>   Then **close and reopen** your PowerShell window.

If you skip this step entirely, the app falls back to the dev defaults hard-coded in `backend\config\db.php`.

---

## 5. Import the schema

This creates all tables and seeds the initial VC and admin accounts.

```powershell
cd C:\projects\UIU_Clearence
Get-Content backend\sql\schema.sql | mysql -u uiu_app -p uiu_clearance
# Enter: devpass

Get-Content backend\sql\02-extend-schema.sql | mysql -u uiu_app -p uiu_clearance
# Enter: devpass
```

> **Tip:** the bundled `backend\sql\import-schema.sh` is a bash script. On Windows, either use the PowerShell commands above, or run it from **Git Bash**.

---

## 6. (Optional) Load test data

Adds 3 students, 3 admins, 1 extra VC, plus sample clearance requests, an emergency request, notifications, and activity log rows. All test accounts share the password `Test@1234`.

```powershell
Get-Content backend\sql\03-seed-test-data.sql | mysql -u uiu_app -p uiu_clearance
# Enter: devpass
```

---

## 7. Make sure the uploads directory is writable

PHP's built-in dev server (which we use in the next step) runs as **your** Windows user, so the `uploads` folder just needs to exist — it inherits your user's permissions by default.

```powershell
cd C:\projects\UIU_Clearence
New-Item -ItemType Directory -Force -Path backend\uploads
```

The app creates per-user subdirectories (`backend\uploads\<user_id>\`) on first upload.

---

## 8. (Optional) Increase PHP upload size limits

The app caps uploads at 100 MB by default (`UPLOAD_MAX_MB` in `.env`). To allow that, raise the PHP limits in `php.ini`:

1. Open `C:\php\php.ini` (or wherever you installed PHP)
2. Find and update these lines:

```ini
upload_max_filesize = 100M
post_max_size       = 110M
```

3. Save the file
4. **No restart needed** — PHP's CLI reads `php.ini` on every invocation.

---

## 9. Start the dev server

From the project root, run PHP's built-in web server:

```powershell
cd C:\projects\UIU_Clearence
php -S localhost:8000
```

> **PowerShell tip:** If PowerShell blocks `php` from running scripts, the only thing you need to allow is the executable itself. The error looks like *"running scripts is disabled on this system"*. To fix, run PowerShell **as Administrator** and execute:
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
> ```
> Then close the admin window and re-open a normal PowerShell.

You should see:

```
[Tue Jun 15 12:00:00 2026] PHP 8.3.x Development Server (http://localhost:8000) started
```

Or use the bundled helper script (works in **Git Bash** on Windows):

```bash
./start-server.sh
```

Open <http://localhost:8000> in your browser. You will be redirected to `auth\login.php`.

---

## 10. Sign in

If you loaded the seed data, use any of these accounts (all share the password `Test@1234`):

| Role    | Email                    |
|---------|--------------------------|
| VC      | `vc@uiu.ac.bd`           |
| VC      | `vc2@uiu.ac.bd`          |
| Admin   | `admin@uiu.ac.bd`        |
| Admin   | `admin.kamal@uiu.ac.bd`  |
| Admin   | `admin.nusrat@uiu.ac.bd` |
| Admin   | `admin.rezaul@uiu.ac.bd` |
| Student | `student.rahim@uiu.ac.bd` |
| Student | `student.karim@uiu.ac.bd` |
| Student | `student.sadia@uiu.ac.bd` |

> **Important:** the login form has an **"I am a…"** role selector. You must pick the role that matches the account. Picking the wrong role for the right email/password is rejected.

The two accounts that exist from `schema.sql` alone (no test data needed) are:

- `vc@uiu.ac.bd` / `Test@1234` (Vice Chancellor)
- `admin@uiu.ac.bd` / `Test@1234` (Department Admin)

---

## 11. Stop the server

Press `Ctrl+C` in the PowerShell window where `php -S` is running.

---

## Troubleshooting

### "php is not recognized as an internal or external command"

PHP is installed but not on your `PATH`. Either:
- Re-do **Step 1.1.4** and make sure you open a **new** PowerShell window afterwards, or
- Replace `php` with the full path, e.g. `C:\php\php.exe -S localhost:8000`

### "mysql is not recognized as an internal or external command"

Same fix as above, but for the MySQL `bin` directory. Usually `C:\Program Files\MySQL\MySQL Server 8.0\bin\`.

### "Access denied for user 'uiu_app'@'localhost'"

The password in your environment (or in `backend\config\db.php`) does not match the one in `01-create-db.sql`. Re-run **Step 3** with the correct password, or update the values in **Step 4** (and the file `backend\config\db.php` if you didn't set env vars).

### "SQLSTATE[HY000] [2002] No such file or directory"

PHP is looking for the MySQL socket in the wrong place. Edit `backend\config\db.php` and change:
```php
$host = getenv('DB_HOST') ?: '127.0.0.1';
```
to:
```php
$host = getenv('DB_HOST') ?: 'localhost';
```
Forcing `localhost` instead of `127.0.0.1` makes PHP use the named-pipe / shared-memory connection on Windows, which is faster and avoids the socket-path issue.

### Upload returns "File is too large"

PHP's `upload_max_filesize` is lower than `UPLOAD_MAX_MB`. See **Step 8**.

### "Class 'finfo' not found" on upload

`php_fileinfo` is not enabled. Edit `php.ini` and uncomment `extension=fileinfo`. See **Step 1.2**.

### Login keeps redirecting back to login.php

- Make sure cookies are enabled in the browser.
- The role picker must match the account's role (student / admin / vc).
- The seeded VC/admin passwords are `Test@1234`. If you changed them, the bcrypt hashes in `schema.sql` lines 75 and 87 are no longer valid — re-hash and re-insert, or use the seed file from **Step 6** to reset.

### Port 8000 already in use

```powershell
php -S localhost:8080
```
Any free port works.

### Backslash vs forward slash in paths

PHP on Windows accepts both. The project uses **forward slashes** in all `<a href>`, `<img src>`, and `header("Location: ...")` calls — these are correct on Windows and should "just work".

### `.env` not being read

See the PowerShell note in **Step 4**. PowerShell does not auto-load `.env` files. Either set the variables in the system Environment Variables dialog, or rely on the hard-coded defaults in `backend\config\db.php`.

---

## Production notes (optional)

This guide runs the dev server. For production on Windows:

1. Use **IIS** (built into Windows) or **Nginx for Windows** with PHP-FPM. **Do not** use `php -S`.
2. Set the IIS/Nginx document root to the project root (so `/auth/login.php` is reachable).
3. Make sure `backend\uploads\` is writable by the IIS application pool user (default: `IIS_IUSRS`).
4. Change `devpass` in both `01-create-db.sql` and your environment to a strong password.
5. Restrict MySQL port 3306 to localhost.
6. Behind a domain, set the session cookie domain — edit `session_set_cookie_params()` in `backend\includes\session.php`.
7. Enable HTTPS; the session cookie has `SameSite=Lax` but no `Secure` flag is set by default.

### IIS quick-start (advanced)

If you want to host on IIS instead of `php -S`:

1. Install IIS: Control Panel → Programs → "Turn Windows features on or off" → check **Internet Information Services** + **CGI**
2. Install **Microsoft Web Platform Installer** and add PHP via it (it sets up the FastCGI handler automatically)
3. In IIS Manager, add a new site pointing to `C:\projects\UIU_Clearence\` with port 80
4. Make sure `backend\uploads\` is writable by the app pool identity

---

## What this guide does NOT do

- It does not install Composer or any PHP package manager (the project uses zero third-party PHP libraries).
- It does not install Apache (Nginx / IIS / `php -S` are all fine for dev).
- It does not push the database to a remote host (Steps 3–6 all use local MySQL).
- It does not migrate the `backend\uploads\` folder from your previous machine — uploaded files are not in version control. Copy them over manually if you need them, preserving the `<user_id>\` directory structure.

---

**You're done. Open <http://localhost:8000> and sign in.**

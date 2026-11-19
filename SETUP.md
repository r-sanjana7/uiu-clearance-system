# Setup Guide — UIU Clearance System on a New Device

A step-by-step guide to get this PHP + MySQL project running on another machine. Tested on Ubuntu 24.04 with PHP 8.3 and MySQL 8.

> **Time required:** ~15–20 minutes on a clean machine.

---

## 1. Prerequisites

Install PHP 8.x, the MySQL server, and the PHP MySQL driver.

```bash
sudo apt update
sudo apt install -y mysql-server php-cli php-mysql
sudo systemctl enable --now mysql
```

Verify the install:

```bash
php -v           # should print PHP 8.x
mysql --version  # should print MySQL 8.x
php -m | grep -i pdo_mysql   # should list `pdo_mysql`
```

> **PHP extensions used by this project:** `pdo_mysql`, `fileinfo`, `session`. All bundled with `php-cli` + `php-mysql` on Debian/Ubuntu. `mbstring` is NOT required.

---

## 2. Copy the project

Place the project folder anywhere. This guide assumes:

```
/home/<you>/UIU_Clearence/
```

(You can rename the folder — it does not affect anything.)

---

## 3. Create the database and the dedicated app user

The SQL script creates a database `uiu_clearance` and a MySQL user `uiu_app` that the app connects as.

```bash
sudo mysql < UIU_Clearence/backend/sql/01-create-db.sql
```

> **Note:** The shipped `01-create-db.sql` sets the app user's password to `devpass`. You can change it in that file before running — just make sure the matching value lands in `.env` (next step).

---

## 4. Create the `.env` file

PHP reads the DB credentials from environment variables. Copy the example and edit if you changed the password in step 3.

```bash
cd UIU_Clearence
cp .env.example .env
```

Edit `.env` if you need a different DB host, port, name, user, or password:

```
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=uiu_clearance
DB_USER=uiu_app
DB_PASS=devpass
DB_CHARSET=utf8mb4
UPLOAD_MAX_MB=100
```

> If you skip this step, the app falls back to the dev defaults hard-coded in `backend/config/db.php`.

---

## 5. Import the schema

This creates all tables (users, documents, login_audit, clearance_requests, clearance_remarks, emergency_requests, notifications, certificates, activity_log) and seeds the initial VC and admin accounts.

```bash
mysql -u uiu_app -p uiu_clearance < backend/sql/schema.sql
# Enter the password you set in step 3 (default: devpass)

mysql -u uiu_app -p uiu_clearance < backend/sql/02-extend-schema.sql
```

---

## 6. (Optional) Load test data

Adds 3 students, 3 admins, 1 extra VC, plus sample clearance requests, an emergency request, notifications, and activity log rows. All test accounts share the password `Test@1234`.

```bash
mysql -u uiu_app -p uiu_clearance < backend/sql/03-seed-test-data.sql
```

---

## 7. Make sure the uploads directory is writable

```bash
mkdir -p backend/uploads
chmod 0755 backend/uploads
```

The app creates per-user subdirectories (`backend/uploads/<user_id>/`) on first upload.

---

## 8. (Optional) Increase PHP upload size limits

The app caps uploads at 100 MB by default (`UPLOAD_MAX_MB` in `.env`). If you want to upload up to that size, raise the PHP ini limits:

```bash
sudo nano /etc/php/8.3/cli/php.ini
```

Add or update:

```
upload_max_filesize = 100M
post_max_size       = 110M
```

> When using `php -S` (the built-in dev server), only the CLI ini matters. If you later switch to Apache or Nginx + PHP-FPM, update the corresponding ini files too.

---

## 9. Start the dev server

From the project root:

```bash
cd UIU_Clearence
php -S localhost:8000
```

Or use the bundled helper script:

```bash
./start-server.sh
```

Open <http://localhost:8000> in a browser. You will be redirected to `auth/login.php`.

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

> **Important:** the login form has a "I am a…" role selector. You must pick the role that matches the account. Picking the wrong role for the right email/password is rejected.

The initial two accounts (from `schema.sql`, no test data required) are:

- `vc@uiu.ac.bd` / `Test@1234` (Vice Chancellor)
- `admin@uiu.ac.bd` / `Test@1234` (Department Admin)

---

## 11. Stop the server

Press `Ctrl+C` in the terminal where `php -S` is running.

---

## Troubleshooting

### "SQLSTATE[HY000] [2002] No such file or directory"

PHP is looking for the MySQL socket in the wrong place. Either:
- Change `DB_HOST` in `.env` from `127.0.0.1` to `localhost` (forces TCP), or
- Set the socket path explicitly in `backend/config/db.php`.

### "Access denied for user 'uiu_app'@'localhost'"

The password in `.env` does not match the one in `01-create-db.sql`. Re-run step 3 with the correct password, or update `.env`.

### Upload returns "File is too large"

PHP's `upload_max_filesize` is lower than `UPLOAD_MAX_MB`. See step 8.

### "Class 'finfo' not found" on upload

`php-fileinfo` is missing. Install it:

```bash
sudo apt install -y php-fileinfo
```

### Login keeps redirecting back to login.php

- Make sure cookies are enabled in the browser.
- The role picker must match the account's role (student / admin / vc).
- The seeded VC/admin passwords are `Test@1234`. If you changed them, the value in `schema.sql` line 75/87 (`$2y$10$mNEAEkMe9...`) is no longer valid — re-hash and re-insert, or use the seed file from step 6 to reset.

### Port 8000 already in use

```bash
php -S localhost:8080   # any free port works
```

---

## Production notes (optional)

This guide runs the dev server. For production:

1. Use Apache or Nginx + PHP-FPM (do not use `php -S`).
2. Set the document root to the project root (so `/auth/login.php` is reachable).
3. Make sure `backend/uploads/` is writable by the PHP-FPM/Apache user (`www-data`).
4. Change `devpass` in both `01-create-db.sql` and `.env` to a strong password.
5. Restrict `phpMyAdmin` / DB port 3306 to localhost.
6. Behind a domain, set the session cookie domain — edit `session_set_cookie_params()` in `backend/includes/session.php`.
7. Enable HTTPS; the session cookie has `SameSite=Lax` but no `Secure` flag is set by default.

---

## What this guide does NOT do

- It does not install Composer or any PHP package manager (the project uses zero third-party PHP libraries).
- It does not install Apache / Nginx (the bundled `php -S` is fine for dev).
- It does not push the database to a remote host (steps 3–6 all use local MySQL).
- It does not migrate the `backend/uploads/` folder from your previous machine — uploaded files are not in version control. Copy them over manually if you need them, preserving the `<user_id>/` directory structure.

---

**You're done. Open <http://localhost:8000> and sign in.**

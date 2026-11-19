# UIU Clearance System

University clearance management web app (PHP). 3 user roles: **Student**, **Department Admin**, **Vice Chancellor**.

## Folder Layout

```
UIU_Clearence/
├── index.php                    entry point — redirects to auth/login.php
│
├── auth/                        login + signup pages
│   ├── login.php
│   ├── signup-student.php
│   └── signup-faculty.php
│
├── student/                     student-facing pages
│   ├── dashboard.php            live status tiles, recent notifications
│   ├── clearance-education.php  per-department apply page (also: library/transport/medical/hostel)
│   ├── apply-clearance.php      full clearance application form
│   ├── track-status.php         live timeline of all 5 departments + completion %
│   ├── upload-document.php      upload ID / fee receipt / library card / transcripts
│   ├── all-documents.php        grid of every uploaded file with download
│   ├── emergency-request.php    submit an urgent clearance request
│   ├── emergency-page.php       my emergency requests inbox
│   ├── notifications.php        in-app notification feed
│   ├── appointment.php          (legacy)
│   └── help.php
│
├── admin/                       department admin pages (5 dept tabs + shared)
│   ├── dashboard.php            real counts, recent requests
│   ├── admin-education.php      generic — used by all 5 dept pages via ?dept=
│   ├── admin-library.php
│   ├── admin-transport.php
│   ├── admin-medical.php
│   ├── admin-hostel.php
│   ├── request-detail.php       single request + remark thread + per-student docs
│   ├── emergency-inbox.php      department admin + VC inbox
│   ├── notifications.php        in-app notification feed
│   ├── user-management.php      list, add, delete students
│   └── student-create.php       add student form
│
├── vc/                          Vice Chancellor
│   ├── dashboard.php            charts, eligible students, certificate issuance
│   ├── certificates.php         eligible queue + issued log
│   ├── activity-log.php         full audit trail
│   ├── user-management.php      tabbed: students + admins
│   ├── student-create.php
│   ├── admin-create.php
│   ├── admin-edit.php
│   ├── request-detail.php       reuses /admin/request-detail.php
│   ├── emergency-inbox.php      reuses /admin/emergency-inbox.php
│   └── notifications.php        reuses /admin/notifications.php
│
├── backend/                     PHP backend (see backend/README.md)
│   ├── config/db.php
│   ├── includes/                auth, session, flash, upload, layout, notifications
│   ├── actions/                 POST handlers (no HTML)
│   ├── sql/                     schema, extension, test data
│   └── uploads/                 student uploaded files (per-user subdirs)
│
└── assets/
    ├── css/                     all *.css stylesheets
    └── images/                  all *.png / *.jpg images
```

## How to Run Locally

```bash
cd UIU_Clearence
php -S localhost:8000
```

Open <http://localhost:8000> — it redirects to `auth/login.php`. Pick a role and sign in.

For the database to work, see **[`backend/README.md`](backend/README.md)** for setup steps.

Moving the project to another machine? See **[`SETUP.md`](SETUP.md)** for a step-by-step install guide.

## Design System

All pages share a single design system defined in `assets/css/theme.css`:

- **Font:** Nunito (Google Fonts) — wide, friendly letterforms chosen for first-time users
- **Color:** `--blue: #2563EB` (primary), neutral grays for text, semantic green/amber/red for status
- **Shell:** `.topbar` + `.sidebar` + `.main` layout, sticky header, fixed left nav on desktop, collapsed on mobile
- **Reusable components:** `.card`, `.btn` (primary/secondary/danger/success/ghost/sm), `.input`, `.field`, `.stat` (with `.ok/.warn/.bad` variants), `.badge` (ok/warn/bad/info), `.table`, `.alert`, `.cl-hero` (clearance page hero with gradient blue)
- **Body variants:** `class="photo-bg"` for login/signup (campus1.png + 0.55 black overlay), `class="plain-bg"` for dashboard pages
- **Page-specific tweaks** live in `assets/css/pageN.css` (kept as design-time placeholders; most are now empty stubs since `theme.css` covers the shared parts)

Pages built with FontAwesome icons (no dependency on missing images like `admin (1).png` etc.).

## Features

### Student
- **Dashboard** with real status tiles (per department) and recent notifications.
- **Apply for clearance** per department: Education, Library, Transport, Medical, Hostel. Each page is a working form that POSTs to `student-submit-clearance.php` and is auto-filled with name/ID/department/email.
- **Upload documents**: ID card, fee receipt, library card, transcripts. Files saved locally under `backend/uploads/<user_id>/`.
- **Track status**: live timeline, completion %, per-department table, remark thread, certificate status.
- **Emergency request**: dedicated form for urgent clearance, with optional supporting document upload. All admins and the VC are notified instantly.
- **All documents / Notifications** pages with download and read-state.

### Department Admin
- **Per-department inbox** (`admin-education.php?dept=education` etc.) with: search by name/ID/email, status filter, real DB counts, sortable table.
- **Row actions**: Approve / Hold / Reject / Block — each with an optional remark saved to the request's thread.
- **Request detail** with full remark history, student profile, and the student's uploaded documents (downloadable).
- **Emergency inbox** to review and decide on urgent requests.
- **User management**: list, add, delete students.

### Vice Chancellor
- **Dashboard** with: total/approved/pending/rejected stats, completed students count, certificate count, emergency counts, **per-department stacked bar chart**, live activity feed, and an "eligible to issue" certificate table.
- **Issue certificate** with one click once all 5 departments are approved; unique serial `CLR-YYYY-NNNNN-XXXX`.
- **Certificates page** showing the eligible queue and a list of every issued certificate.
- **Activity log** with full audit trail of clearance decisions, emergency decisions, and certificate issuance.
- **User management** with two tabs: students (CRUD) + admins (CRUD + reset password + suspend).

### Notifications
In-app notification feed (bell icon in topbar) for:
- Request submitted
- Status update (approved / rejected / on hold / blocked)
- Admin remark
- Emergency submitted / approved / rejected

Each user can mark individual notifications or "mark all as read".

## Test Data

When you load `backend/sql/03-seed-test-data.sql`, you get:

| Role    | Email                    | Password   |
|---------|--------------------------|------------|
| VC      | `vc@uiu.ac.bd`           | `Test@1234` |
| VC      | `vc2@uiu.ac.bd`          | `Test@1234` |
| Admin   | `admin@uiu.ac.bd`        | `Test@1234` |
| Admin   | `admin.kamal@uiu.ac.bd`  | `Test@1234` |
| Admin   | `admin.nusrat@uiu.ac.bd` | `Test@1234` |
| Admin   | `admin.rezaul@uiu.ac.bd` | `Test@1234` |
| Student | `student.rahim@uiu.ac.bd` | `Test@1234` |
| Student | `student.karim@uiu.ac.bd` | `Test@1234` |
| Student | `student.sadia@uiu.ac.bd` | `Test@1234` |

Plus 15 pre-seeded clearance requests (5 per student), 1 emergency request, 8 notifications, and 3 activity-log entries. Same shared password for everyone.

## Reorganization + Redesign Notes

- The folder was reorganized on 2026-06-15 from a flat layout of ~30 PHP files.
- Generic filenames (`page1.php`...`page17.php`) were renamed to descriptive names.
- Typos in filenames were fixed: `appoinment` → `appointment`, `emegency` → `emergency`, `Upload` → `upload`, `VC` → `vc`.
- Duplicate `page12 copy.php` and `VC-removebg-preview.png` were removed (byte-identical to existing files).
- All `href`, `src`, and `header("Location: ...")` references inside the PHP files were updated to match the new directory structure.
- All pages were redesigned to share `theme.css` — same Nunito font, same blue accent, same topbar+sidebar+main shell, same card/table/button system.
- 2026-06-15: added real backend integration — all clearance application / status updates / emergency requests / certificate issuance / user management endpoints and pages now read and write the database.

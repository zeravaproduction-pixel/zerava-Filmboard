# Zerava Filmboard

Aplikasi komunitas dan ruang produksi film Zerava Studio. Frontend React + TypeScript + Vite, Supabase-ready, dan PWA-ready.

## Jalankan di PC

1. Install **Node.js LTS** dan Git.
2. Ekstrak folder project, buka folder `zerava-filmboard` di VS Code.
3. Buka Terminal lalu jalankan:

```bash
npm install
npm run dev
```

4. Buka URL lokal yang ditampilkan Vite (biasanya `http://localhost:5173`).

## Hubungkan Supabase

1. Buat project baru di https://supabase.com (free tier).
2. Buka **SQL Editor → New query**, salin seluruh isi `supabase/schema.sql`, lalu klik Run.
3. Buka **Project Settings → API**. Salin Project URL dan anon/publishable key.
4. Duplikat `.env.example` menjadi `.env.local`, lalu isi:

```env
VITE_SUPABASE_URL=https://PROJECT-REF.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

5. Di Authentication → Providers, aktifkan Email dan Google. Untuk Google, buat OAuth Client di Google Cloud Console, isi Client ID/Secret di Supabase, dan daftarkan callback URL yang ditampilkan Supabase. Atur Site URL dan Redirect URLs untuk localhost dan domain Vercel.
6. Buat bucket Storage bernama `avatars`, `community-media`, dan `project-assets`. Tambahkan Storage RLS policies sebelum membuka fitur upload kepada anggota.
7. Aktifkan Realtime untuk tabel yang dibutuhkan (posts, messages, notifications) dari Database → Publications.

**Penting:** schema adalah fondasi awal, bukan kebijakan keamanan final. Sebelum membuka pendaftaran publik, tinjau seluruh RLS, tambahkan aturan membership/role untuk channel, server, dan project, serta Storage policies. Jangan pernah menaruh `service_role` key di frontend.

## GitHub

Buat repository kosong bernama `zerava-filmboard`, lalu dari terminal folder project:

```bash
git init
git add .
git commit -m "Initial Zerava Filmboard app"
git branch -M main
git remote add origin https://github.com/USERNAME/zerava-filmboard.git
git push -u origin main
```

Ganti `USERNAME` dengan username GitHub kamu. Jangan commit `.env.local` (sudah diabaikan oleh `.gitignore`).

## Deploy Vercel

1. Login ke https://vercel.com menggunakan GitHub.
2. Klik **Add New → Project**, import repository `zerava-filmboard`.
3. Framework preset: Vite. Build command `npm run build`; output directory `dist`.
4. Tambahkan Environment Variables `VITE_SUPABASE_URL` dan `VITE_SUPABASE_ANON_KEY`.
5. Klik Deploy. Setelah domain tersedia, masukkan domain tersebut ke Supabase Auth → URL Configuration → Site URL dan Redirect URLs.

## StackBlitz

Buka https://stackblitz.com, pilih **Import from GitHub**, lalu masukkan URL repository. Bisa juga upload ZIP project ini ke StackBlitz.

## Fitur dalam starter ini

- Dashboard cinematic responsif dengan dark/light mode.
- Navigasi seluruh modul komunitas dan produksi.
- Activity feed demo, composer teks, like lokal, pencarian feed.
- Ringkasan proyek, agenda, anggota, dan tampilan modul.
- Modal demo untuk aksi buat konten.
- Logo Zerava, manifest PWA, Supabase client config.
- Skema SQL awal untuk profil, server, channel, posts, projects, crew, screenplay, shot list, budget, academy, bookmarks, chat, dan notifications.

## Status implementasi

UI starter dan fondasi database sudah disiapkan. Data dashboard saat ini sebagian besar masih data demo/lokal. Login Google/email, CRUD seluruh modul, upload media, chat realtime, notifikasi terjadwal, kalender, serta aturan role-permission perlu dihubungkan dan diuji terhadap project Supabase milikmu. Fitur-fitur itu tidak otomatis aktif hanya dengan mengisi URL/key.

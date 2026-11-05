# 🚛 Dashboard Realisasi Pengiriman & Display Conveyor Realtime
### Pabrik Rembang (Plant 5401) — PT Semen Gresik

Dashboard interaktif mandiri (*single-page application*) untuk monitoring realisasi pengiriman semen dan status antrean conveyor secara langsung (*realtime*) dari sistem SIG Intransit.

---

## ✨ Fitur Utama

1. **Dashboard Realisasi Pengiriman:**
   - Rekap KPI: Total SPJ/DO, Total Tonase (Zak & Curah), Lead Time, Dwell Time, Rata-rata Muatan per Truk.
   - Visualisasi: Grafik ritase & tonase per jam, sebaran shift (Shift 1, 2, 3), sebaran kota/kabupaten tujuan (Jawa Tengah, Jawa Timur, DIY), produk, distributor, dan ekspeditur.
   - Mode Gelap / Terang (*Dark/Light Mode*), Filter tanggal, status, kemasan, pencarian cerdas nomor plat/driver/distributor.

2. **Display Conveyor Realtime:**
   - Monitoring live Conveyor 01 s.d. 05 (Semen Zak) dan Conveyor 90 s.d. 92 (Semen Curah).
   - Status terperinci per conveyor: Jumlah truk sudah masuk plant (*loading*), jumlah truk antri yang sudah *booking*, estimasi waktu tunggu, dan rincian per produk.
   - Kartu antrean detail untuk setiap unit truk lengkap dengan nama driver, ekspeditur, produk, tujuan, dan lama di plant.

3. **Deteksi Otomatis Truk Keluar Plant (Realtime):**
   - Saat truk yang sedang *loading* keluar dari plant, sistem secara otomatis mendeteksi pelepasan status, mengonversinya menjadi data Realisasi (Status 70), dan mencatatnya ke grafik & tabel hari ini secara otomatis tanpa perlu input manual.
   - Banner notifikasi live langsung muncul di bagian atas Dashboard Utama.

---

## 🚀 Panduan Deploy ke GitHub Pages (Online)

Dashboard ini dirancang agar dapat diakses dari mana saja (Laptop, Tablet, HP Android/iPhone, hingga Smart TV Control Room) melalui **GitHub Pages** secara gratis dan bebas kendala CORS (*Cross-Origin Resource Sharing*).

### Langkah 1: Buat Repositori di GitHub
1. Buka [GitHub.com](https://github.com/) dan buat repositori baru (misal: `cp-rembang-dashboard`).
2. Atur repositori sebagai **Public**.

### Langkah 2: Upload / Push File ke Repositori
Anda dapat meng-upload seluruh isi folder ini ke GitHub:
- **Cara A (Upload via Web Browser):**
  1. Di halaman repositori GitHub Anda, klik **Add file** > **Upload files**.
  2. Drag & drop seluruh isi folder ini (`index.html`, folder `.github`, folder `data`, folder `api`, `README.md`, dll).
  3. Klik **Commit changes**.
- **Cara B (Menggunakan Git CLI):**
  ```bash
  git init
  git add .
  git commit -m "feat: initial commit dashboard realisasi rembang"
  git branch -M main
  git remote add origin https://github.com/<USERNAME-ANDA>/<NAMA-REPO>.git
  git push -u origin main
  ```

### Langkah 3: Aktifkan Izin Tulis GitHub Actions (Sangat Penting!)
Agar bot GitHub Actions dapat memperbarui data SIG secara otomatis setiap 10 menit:
1. Masuk ke repositori Anda di GitHub, klik tab **Settings** (di bilah atas).
2. Di menu samping kiri, klik **Actions** > **General**.
3. Gulir ke bawah hingga menemukan bagian **Workflow permissions**.
4. Pilih opsi **Read and write permissions**.
5. Centang juga opsi *"Allow GitHub Actions to create and approve pull requests"* jika tersedia.
6. Klik tombol **Save**.

### Langkah 4: Aktifkan GitHub Pages
1. Masih di tab **Settings**, pilih menu **Pages** di bilah kiri.
2. Pada bagian **Build and deployment**:
   - **Source**: Pilih `Deploy from a branch`.
   - **Branch**: Pilih `main` dan folder `/ (root)`.
3. Klik tombol **Save**.
4. Tunggu sekitar 1–2 menit. URL dashboard Anda akan muncul di bagian atas halaman Settings > Pages:
   ```
   https://<username>.github.io/<nama-repo>/
   ```
   *(Contoh: `https://afidr.github.io/cp-rembang-dashboard/`)*

---

## 🔄 Bagaimana Cara Kerja Sinkronisasi Realtime?

Dashboard ini memiliki arsitektur **multi-jalur cerdas**:

1. **Jalur GitHub Actions (Otomatis & Bebas CORS di semua perangkat):**
   - File workflow [`.github/workflows/sync-sig.yml`](.github/workflows/sync-sig.yml) akan berjalan otomatis setiap 10 menit di server GitHub.
   - Script mengambil data dari `https://app.sig.id/sgg/sd/intransit/index.php/dashboard/get_data_all`, menyimpannya ke [`data/realtime.json`](data/realtime.json), dan melakukan commit otomatis.
   - Karena file JSON berada di domain yang sama dengan dashboard, browser di HP maupun Smart TV tidak akan terblokir oleh batasan CORS browser.

2. **Jalur Server Lokal (Update Tiap 15–30 Detik untuk Operator di Pabrik):**
   - Bila ingin pemantauan langsung dengan jeda super singkat (15–30 detik):
   - Cukup klik ganda file **`jalankan-realtime.bat`** di komputer Windows Anda.
   - Browser akan otomatis terbuka di `http://127.0.0.1:8088`.
   - Server lokal PowerShell langsung menjembatani data dari SIG tanpa CORS, dan jendela konsol akan menampilkan log setiap kali ada truk yang keluar plant:
     ```text
     [19:35:10] Sinkronisasi SIG Realtime berhasil (8151 bytes)
     [19:35:40] [TRUK KELUAR] Plat K8657OF (A Jalil - 32 ton ke Karanganyar) -> Masuk ke Realisasi!
     ```

3. **Jalur Serverless Vercel (Opsional):**
   - File [`api/sig.js`](api/sig.js) sudah disertakan. Jika repositori ini diimpor ke [Vercel](https://vercel.com/), Vercel otomatis menyediakan endpoint `/api/sig` yang bekerja sebagai reverse proxy bebas CORS dengan update langsung 0-detik.

---

## 📁 Struktur Folder Repositori

```text
cp-rembang-dashboard/
├── .github/
│   └── workflows/
│       └── sync-sig.yml         # GitHub Actions cron scheduler (tiap 10 menit)
├── api/
│   └── sig.js                   # Serverless reverse proxy (opsional untuk Vercel)
├── data/
│   └── realtime.json            # Snapshot data realtime SIG terbaru
├── index.html                   # File Dashboard utama (HTML + CSS + JS interaktif)
├── jalankan-realtime.bat        # Launcher 1-klik untuk server lokal Windows
├── server-realtime.ps1          # Script server lokal PowerShell bebas CORS
├── .gitignore                   # Konfigurasi file yang diabaikan git
└── README.md                    # Dokumentasi lengkap proyek
```

---

## 💡 Troubleshooting & Tips

- **Data di GitHub Pages belum terbarui:**
  Buka tab **Actions** di repositori GitHub Anda, klik workflow **Sync SIG Realtime Data**, lalu klik tombol **Run workflow** untuk menjalankan sinkronisasi secara manual kapan saja.
- **Membuka file `index.html` secara langsung (double click offline):**
  Jika file dibuka langsung dengan URL `file:///...`, browser membatasi koneksi langsung ke `app.sig.id`. Gunakan file `jalankan-realtime.bat` agar koneksi live aktif sempurna.
- **Mengubah target Plant SIG:**
  Pada tab **Display Conveyor**, terdapat dropdown pilihan Plant:
  - `5401 · CP Rembang SG (5000)` (Default)
  - `7416 · CP Rembang SG (7000)`
  - `7403 · UP Tuban (7000)`

---

*Dikembangkan untuk operasional PT Semen Gresik — Pabrik Rembang.*

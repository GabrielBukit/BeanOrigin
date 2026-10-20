# 🫘 BeanOrigin — Concept Maturation Document
> Platform Rantai Pasok & Verifikasi Ekspor Kopi Nusantara  
> Berbasis LBS, AI Vision, dan Blockchain

---

## 1. Ringkasan Visi

**BeanOrigin** adalah aplikasi mobile Flutter multi-role yang menghubungkan ekosistem supply chain kopi Indonesia — dari perkebunan petani lokal hingga bursa komoditas internasional — dengan memanfaatkan teknologi modern: AI Computer Vision, LLM advisory, blockchain hash-chain, LBS, dan sensor perangkat.

---

## 2. Peta Peran Pengguna (User Roles)

| Role | Tugas Utama |
|---|---|
| 🌱 **Petani (Farmer)** | Mendaftarkan batch panen, input data kebun, geo-tag lokasi |
| 🔬 **Q-Grader / Kurator Mutu** | Scan AI defect biji kopi, isi form cupping score, verifikasi batch |
| 📦 **Eksportir** | Monitor logistik kontainer, sinkronisasi jam lelang London, transaksi |
| 👤 **Admin** | Manajemen user, validasi akhir batch untuk ekspor |

> **Pertanyaan Terbuka #1**: Apakah semua role ini perlu diimplementasi, atau cukup 2 role utama (misal: Petani + Eksportir) untuk scope tugas akhir?

---

## 3. Pemetaan Kriteria Tugas Akhir → Fitur Aplikasi

### ✅ 3.1 Konversi Waktu
- **Zona**: WIB (UTC+7), WITA (UTC+8), WIT (UTC+9), London (UTC+0/+1 BST)
- **Konteks**: Widget "Auction Clock" di halaman Home — menampilkan countdown dan jam saat ini di 4 zona waktu sekaligus
- **Trigger**: Jam pembukaan ICE Futures Europe pukul 10:00 London time → dikonversi realtime ke WIB/WITA/WIT

### ✅ 3.2 Konversi Mata Uang
- **Mata uang**: IDR 🇮🇩, USD 🇺🇸, GBP 🇬🇧, EUR 🇪🇺
- **API**: [Frankfurter API](https://frankfurter.app/) — free, tanpa API key, berbasis data European Central Bank. IDR **terkonfirmasi tersedia**.
- **Konteks**: Halaman "Market Price" — harga kopi green bean per kg dalam 4 mata uang, update realtime

### ✅ 3.3 LBS (Location-Based Service)
- **Fitur 1**: Geo-tag perkebunan asal (Farmer input koordinat GPS saat daftar batch)
- **Fitur 2**: Peta rute kontainer dari gudang → pelabuhan ekspor terdekat
- **Library**: `flutter_map` (OpenStreetMap) + `geolocator` — gratis, tanpa API key
- **Data**: Titik perkebunan ditampilkan di peta dengan pin berwarna sesuai status batch (pending/verified/exported)

### ✅ 3.4 Sensor

#### Sensor 1 — Accelerometer (Cargo Shock Monitor)
- Membaca data accelerometer saat transit pengiriman
- Jika guncangan melebihi threshold (misal >2G), sistem mencatat "shock event" ke log batch
- **Fitur Bonus**: "Shake to Random Inspect" — kocok HP untuk memilih sampel karung secara acak

#### Sensor 2 — Gyroscope (Slope Meter)
- Mengukur sudut kemiringan lahan kebun / rak penjemuran
- Ditampilkan sebagai clinometer visual (bubble level)
- Data kemiringan tersimpan sebagai metadata batch kebun

### ✅ 3.5 AI Vision — Green Coffee Defect Classifier
- **Model**: MobileNetV2 / YOLOv8-Nano (TFLite, on-device)
- **Input**: Foto biji kopi dari kamera HP
- **Output**: Klasifikasi cacat — Normal, Black Bean, Sour/Moldy, Broken, dll.
- **Integrasi**: Q-Grader buka kamera → scan → hasil defect % langsung masuk form inspeksi batch
- **Catatan**: Model TFLite perlu di-train/fine-tune dengan dataset biji kopi — perlu diputuskan apakah menggunakan pre-trained atau simulasi placeholder

### ✅ 3.6 LLM — Export & Roasting Advisory
- **Model**: Google Gemini 1.5 Flash (via Gemini API)
- **Input**: Data batch (elevasi mdpl, varietas, kadar air, proses pascapanen, cupping score)
- **Output**:
  - Rekomendasi roasting profile (light/medium/dark, suhu, durasi)
  - Cupping notes deskripsi rasa (floral, fruity, dll.)
  - Checklist kepatuhan regulasi ekspor (SNI, SCAA standard)

### ✅ 3.7 Blockchain — Immutable Provenance Ledger
- **Mekanisme**: SHA-256 hash-chain lokal (bukan blockchain publik)
- **Struktur Blok**:
  ```json
  {
    "index": 1,
    "timestamp": "2026-10-19T10:00:00Z",
    "batch_data": {
      "variety": "Arabika Gayo",
      "elevation_masl": 1600,
      "origin": "Aceh Tengah",
      "process": "Washed",
      "cupping_score": 85.5
    },
    "previous_hash": "0000abc...",
    "hash": "sha256(index+timestamp+data+previous_hash)"
  }
  ```
- **QR Code**: Pembeli scan → aplikasi validasi hash chain → tampilkan sertifikat keaslian
- **Storage**: Blok disimpan di Supabase (online) + Hive (offline cache)

### ✅ 3.8 Mini Game — BeanSorter Blitz
- **Gameplay**: Biji kopi jatuh dari atas layar, user tap biji cacat ke tempat sampah, biji normal ke wadah ekspor
- **Kontrol**: Tap layar + opsional kontrol kemiringan gyroscope untuk gerak karakter/wadah
- **Level**: Makin cepat conveyor, makin sulit
- **Edukasi**: Setelah game, tampilkan fakta tentang defect yang baru disortir

### ✅ 3.9 Pencarian & Filter Batch
- Filter: Varietas, Daerah Asal, Cupping Score (range), Status (available/sold), Rentang harga
- Search bar dengan debounce
- Tampilan grid card batch kopi

### ✅ 3.10 Notifikasi
- **Tipe**:
  - Alarm jam buka sesi lelang London (Local Notification terjadwal)
  - Alert perubahan harga kurs >1% (triggered setelah fetch currency)
  - Status batch berubah (pending → verified → ready to export)
- **Library**: `flutter_local_notifications`

### ✅ 3.11 Autentikasi & Keamanan
- **Login**: Email + Password (hash SHA-256 atau bcrypt di client sebelum kirim ke server)
- **Session**: JWT disimpan di `flutter_secure_storage`
- **Biometric**: Fingerprint / Face ID via `local_auth` (sebagai alternatif login setelah session aktif)
- **Tanpa Firebase Auth** ✓

### ✅ 3.12 Database
- **Lokal**: Hive (NoSQL) — cache form inspeksi offline, blok blockchain lokal
- **Online**: Supabase (PostgreSQL) — user, batch, blockchain ledger, market data

### ✅ 3.13 Bottom Navigation
1. 🏠 **Home / Batch Explorer** — dashboard + list batch + filter
2. 👤 **Profil** — foto, data user, statistik batch
3. 💬 **Saran & Kesan** — form feedback mata kuliah PaM
4. 🚪 **Logout** — clear session + konfirmasi

### ✅ 3.14 Plantation Weather Monitor (Open-Meteo API)
- **API**: [Open-Meteo](https://open-meteo.com/) — free, tanpa API key, tanpa registrasi
- **Input**: Koordinat latitude/longitude dari geo-tag kebun petani (sudah tersedia dari fitur LBS)
- **Data yang diambil**:
  - Suhu udara (°C)
  - Kelembaban relatif (%)
  - Curah hujan saat ini (mm)
  - Prakiraan hujan 7 hari ke depan
- **Tampilan**: Widget cuaca di halaman detail kebun/batch milik Petani
- **Integrasi LLM**: Data cuaca dikirim ke Gemini sebagai konteks tambahan untuk rekomendasi agronomis (misal: "Hujan 3 hari ke depan, tunda penjemuran")
- **Alert**: Notifikasi lokal jika prakiraan hujan > threshold → peringatan angkat jemuran biji kopi
- **Contoh request**:
  ```
  GET https://api.open-meteo.com/v1/forecast
    ?latitude=-4.6167&longitude=96.8333
    &current=temperature_2m,relative_humidity_2m,precipitation,rain
    &forecast_days=7&timezone=Asia/Jakarta
  ```

---

## 4. Arsitektur Teknis

```
┌─────────────────────────────────────────────────────┐
│                  FLUTTER APP                        │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ UI Layer │  │  State   │  │   Service Layer  │  │
│  │ (Screens)│  │  (Bloc/  │  │ ┌──────────────┐ │  │
│  │          │  │  Cubit)  │  │ │ AI Service   │ │  │
│  └──────────┘  └──────────┘  │ │ (TFLite)     │ │  │
│                              │ ├──────────────┤ │  │
│                              │ │ LLM Service  │ │  │
│                              │ │ (Gemini API) │ │  │
│                              │ ├──────────────┤ │  │
│                              │ │ Blockchain   │ │  │
│                              │ │ Service      │ │  │
│                              │ ├──────────────┤ │  │
│                              │ │ Frankfurter  │ │  │
│                              │ │ (Currency)   │ │  │
│                              │ ├──────────────┤ │  │
│                              │ │ Open-Meteo   │ │  │
│                              │ │ (Weather)    │ │  │
│                              │ ├──────────────┤ │  │
│                              │ │ flutter_map  │ │  │
│                              │ │ (OSM + GPS)  │ │  │
│                              │ └──────────────┘ │  │
│                              └──────────────────┘  │
├─────────────────────────────────────────────────────┤
│              LOCAL STORAGE (Hive)                   │
├─────────────────────────────────────────────────────┤
│           ONLINE (Supabase / PostgreSQL)            │
└─────────────────────────────────────────────────────┘
```

**State Management**: Bloc/Cubit  
**Navigasi**: GoRouter

---

## 5. Struktur Layar (Screen Map)

```
Splash Screen
└── Auth
    ├── Login (email + biometric)
    └── Register
└── Main Shell (Bottom Nav)
    ├── [1] Home / Batch Explorer
    │   ├── Dashboard (Auction Clock, Harga Kopi, Peta Sentra)
    │   ├── Batch List (search + filter)
    │   └── Batch Detail
    │       ├── Blockchain Certificate (QR)
    │       ├── AI Advisor (LLM)
    │       └── Logistik Tracker (Map)
    ├── [2] Profil
    │   ├── Edit Profil (foto)
    │   └── Statistik Batch
    ├── [3] Saran & Kesan
    └── [4] Logout
└── Feature Screens (akses dari Home/Batch)
    ├── AI Defect Scanner (Kamera)
    ├── Sensor Monitor (Accelerometer + Gyroscope)
    ├── Add/Edit Batch Form
    ├── Geo-tag Map Picker
    ├── Market Prices (Currency Converter — Frankfurter API)
    ├── Plantation Weather Monitor (Open-Meteo API)
    └── Mini Game (BeanSorter Blitz)
```

---

## 6. Keputusan Teknis yang Perlu Dikonfirmasi

| # | Keputusan | Pilihan ✅ | Catatan |
|---|---|---|---|
| 1 | State Management | **Bloc/Cubit** | Familiar, banyak tutorial |
| 2 | Model AI TFLite | **Transfer learning MobileNetV2** | Simulasi label kopi, cepat jalan di emulator |
| 3 | Storage online | **Supabase** (PostgreSQL BaaS) | Setup cepat, ada built-in storage |
| 4 | User roles | **Full multi-role** | Petani, Q-Grader, Eksportir, Admin |
| 5 | Currency API | **Frankfurter API** | Free, tanpa API key, IDR tersedia ✓ |
| 6 | Map provider | **OpenStreetMap** via flutter_map | Gratis, tanpa API key |
| 7 | Mini game engine | **Pure Flutter Canvas/CustomPaint** | Tidak perlu dependency tambahan |
| 8 | Weather API | **Open-Meteo API** | Free, tanpa API key, data pertanian lengkap |

---

## 7. Potensi Tantangan & Mitigasi

| Tantangan | Mitigasi |
|---|---|
| Model TFLite training memerlukan dataset | Gunakan transfer learning dari model pre-trained + label simulasi untuk demo |
| Biometric login di emulator tidak support | Fallback ke PIN / skip jika `local_auth` unavailable |
| Supabase setup & RLS policy kompleks | Mulai dengan tabel sederhana tanpa RLS, tambahkan policy setelah fitur utama jalan |
| Blockchain hash-chain perlu konsistensi offline-online | Simpan blok di Hive dahulu, sync ke Supabase saat online |
| Gemini API quota | Implementasi rate limiting + caching hasil LLM per batch |

---

## 8. Checklist Kriteria Tugas Akhir

- [ ] Konsep projek akhir ✓ (dokumen ini)
- [ ] Login enkripsi (non-Firebase) + session (JWT)
- [ ] Login biometric (Fingerprint via local_auth)
- [ ] Database lokal (Hive) + online (Supabase)
- [ ] Web service / API (Frankfurter, Open-Meteo, Gemini, Supabase REST) + LBS (OpenStreetMap)
- [ ] Bottom navigation (Home, Profil, Saran & Kesan, Logout)
- [ ] Konversi mata uang — IDR, USD, GBP, EUR (Frankfurter API)
- [ ] Konversi waktu — WIB, WITA, WIT, London
- [ ] Sensor Accelerometer (Cargo Shock Monitor)
- [ ] Sensor Gyroscope (Slope Meter / Clinometer)
- [ ] Sensor Biometric Fingerprint (login biometric)
- [ ] Fitur AI — Computer Vision MobileNetV2/TFLite (Defect Classifier)
- [ ] Fitur LLM — Gemini 1.5 Flash (Export & Roasting Advisory)
- [ ] Mini game — BeanSorter Blitz (Flutter Canvas)
- [ ] Pencarian & pemilihan (filter batch kopi)
- [ ] Notifikasi mobile (flutter_local_notifications)
- [ ] Blockchain sederhana (SHA-256 hash-chain + QR Code)
- [ ] Plantation Weather Monitor (Open-Meteo API) ← *fitur tambahan*

**Status: 15/15 kriteria wajib terpetakan ✅ + 1 fitur bonus ✅**

---

## 9. Stack Teknologi Final

| Kategori | Teknologi |
|---|---|
| Framework | Flutter (Android + iOS) |
| State Management | Bloc / Cubit |
| Navigasi | GoRouter |
| DB Lokal | Hive |
| DB Online | Supabase (PostgreSQL) |
| Auth | JWT + flutter_secure_storage + local_auth |
| Peta | flutter_map + OpenStreetMap + geolocator |
| Cuaca | Open-Meteo API |
| Mata Uang | Frankfurter API |
| AI On-Device | MobileNetV2 / TFLite |
| LLM | Google Gemini 1.5 Flash API |
| Blockchain | SHA-256 hash-chain (custom) + QR code |
| Notifikasi | flutter_local_notifications |
| Mini Game | Flutter Canvas / CustomPaint |
| Sensor | accelerometer, gyroscope, local_auth (biometric) |

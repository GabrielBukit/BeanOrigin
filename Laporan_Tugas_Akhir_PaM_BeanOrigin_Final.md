# LAPORAN TUGAS MATA KULIAH PEMROGRAMAN APLIKASI MOBILE
## PENGEMBANGAN APLIKASI “BeanOrigin”
### Platform Rantai Pasok & Verifikasi Ekspor Kopi Nusantara Berbasis LBS, AI Vision, dan Blockchain

---

**Disusun Oleh:**  
- **Muhammad Al Furqan** — 124240008  
- **Gabriel Bukit** — 124240032  

**PROGRAM STUDI SISTEM INFORMASI**  
**JURUSAN INFORMATIKA**  
**FAKULTAS TEKNIK INDUSTRI**  
**UNIVERSITAS PEMBANGUNAN NASIONAL “VETERAN” YOGYAKARTA**  
**2026**

---

## HALAMAN PENGESAHAN
TUGAS MATA KULIAH PEMROGRAMAN APLIKASI MOBILE  
**BEANORIGIN**  
PEMROGRAMAN APLIKASI MOBILE KELAS SI-D  

Disusun Oleh:  
- Muhammad Al Furqan (124240008)  
- Gabriel Bukit (124240032)  

Telah Diperiksa dan Disetujui oleh Dosen Pengampu Mata Kuliah Pemrograman Aplikasi Mobile pada tanggal: Oktober 2026  

**Dosen Pengampu:**  
**Bagus Muhammad Akbar, S.ST., M.Kom.**

---

## KATA PENGANTAR
Segala puji dan syukur penulis panjatkan ke hadirat Allah SWT atas limpahan rahmat, taufik, dan hidayah-Nya, sehingga laporan Proyek Akhir Mata Kuliah Pemrograman Aplikasi Mobile yang berjudul **“BeanOrigin”** ini dapat diselesaikan dengan baik dan tepat waktu. Laporan ini disusun sebagai salah satu bentuk pemenuhan tugas pada mata kuliah Pemrograman Aplikasi Mobile, sekaligus menjadi sarana untuk memperluas wawasan dan pemahaman mengenai konsep serta penerapan pengembangan aplikasi mobile di dunia nyata.

Ucapan terima kasih yang sebesar-besarnya disampaikan kepada **Bapak Bagus Muhammad Akbar, S.ST., M.Kom.**, selaku dosen pengampu mata kuliah Pemrograman Aplikasi Mobile, atas ilmu, bimbingan, dan arahan yang telah beliau berikan selama proses pembelajaran hingga penyusunan laporan ini.

BeanOrigin lahir dari keinginan untuk menghadirkan transparansi pada rantai pasok kopi Nusantara, mulai dari kebun petani hingga pasar ekspor. Semoga laporan ini dapat memberikan manfaat, baik bagi penyusun maupun pembaca yang ingin memahami lebih dalam mengenai pengembangan aplikasi mobile lintas platform. Penyusun menyadari bahwa laporan ini masih jauh dari kata sempurna, sehingga kritik dan saran yang membangun sangat diharapkan demi penyempurnaan di masa mendatang.

*Yogyakarta, Oktober 2026*  
**Penyusun**

---

## DAFTAR ISI
- **HALAMAN PENGESAHAN**
- **KATA PENGANTAR**
- **DAFTAR ISI**
- **BAB I LANDASAN TEORI DAN TEMA APLIKASI**
  - 1.1 Latar Belakang Masalah
  - 1.2 Tema & Filosofi Desain Aplikasi BeanOrigin
  - 1.3 Landasan Teori Komprehensif
    - 1.3.1 Framework Flutter dan Bahasa Dart
    - 1.3.2 Basis Data Lokal Hive dan Online Supabase
    - 1.3.3 Keamanan Data, Hashing SHA-256, JWT, dan Biometrik
    - 1.3.4 Integrasi Web Service & RESTful API
    - 1.3.5 Location-Based Services (LBS) & Peta OpenStreetMap
    - 1.3.6 Pemanfaatan Sensor Perangkat
    - 1.3.7 Computer Vision On-Device (TFLite)
    - 1.3.8 Blockchain Hash-Chain & QR Code
    - 1.3.9 Notifikasi Lokal Terjadwal
    - 1.3.10 Ergonomi Mobile & Hukum “Mobile Thumb Zone”
- **BAB II PERANCANGAN SISTEM**
  - 2.1 Analisis Kebutuhan Perangkat Lunak (SRS)
    - 2.1.1 Kebutuhan Fungsional (Functional Requirements)
    - 2.1.2 Kebutuhan Non-Fungsional (Non-Functional Requirements)
  - 2.2 Use Case Diagram
  - 2.3 Deskripsi Use Case
  - 2.4 Activity Diagram
    - 2.4.1 Registrasi, Login, dan Autentikasi Biometrik
    - 2.4.2 Pindai Defect Biji Kopi (AI Vision)
    - 2.4.3 Tambah Batch Panen & Geo-tag LBS (Offline-First)
    - 2.4.4 AI Roasting & Export Advisory (Gemini API)
    - 2.4.5 Cek Keaslian Batch via QR Code Blockchain
    - 2.4.6 Pemantauan Cuaca Kebun & Notifikasi Hujan (Open-Meteo)
    - 2.4.7 Monitoring Guncangan Kargo (Accelerometer & Gyroscope)
    - 2.4.8 Konverter Valas & Auction Clock London (Frankfurter)
    - 2.4.9 Mini Game Edukasi BeanSorter Blitz (Endless Survival Mode)
    - 2.4.10 Modul Saran & Kesan (Dual-Tab System)
  - 2.5 Sequence Diagram
    - 2.5.1 Login Email dan Biometrik Native
    - 2.5.2 AI Roasting & Export Advisory dengan Caching Hive
    - 2.5.3 Verifikasi Keaslian Batch melalui QR Code Hash-Chain
    - 2.5.4 Pemindaian Defect AI on-Device & Verifikasi Mutu SCA
    - 2.5.5 Perekaman Sensor Accelerometer & Guncangan Kargo
  - 2.6 Arsitektur Sistem
  - 2.7 Class Diagram (Diagram Kelas)
  - 2.8 Perancangan Antarmuka Pengguna (Wireframe & Mockup)
- **BAB III IMPLEMENTASI DAN PENJELASAN SOURCE CODE DETAIL**
  - 3.1 Struktur Proyek (Feature-First Clean Architecture)
  - 3.2 Modul Autentikasi & Manajemen Sesi
  - 3.3 Blockchain Hash-Chain & Verifikasi QR
  - 3.4 Akses Sensor Accelerometer (Cargo Shock Monitor)
  - 3.5 Konverter Mata Uang (Frankfurter API)
  - 3.6 Plantation Weather Monitor (Open-Meteo API)
  - 3.7 AI Roasting & Export Advisory (Gemini API)
  - 3.8 Hasil Tampilan Antarmuka dan Demonstrasi Fitur Aplikasi
- **BAB IV LEMBAR EVALUASI PENGUJIAN PERANGKAT LUNAK**
  - 4.1 Lingkungan Pengujian
  - 4.2 Tabel Pengujian Black Box
  - 4.3 Evaluasi & Pembahasan Hasil Pengujian
- **BAB V KESIMPULAN DAN SARAN**
  - 5.1 Kesimpulan
  - 5.2 Saran

---

# BAB I  
# LANDASAN TEORI DAN TEMA APLIKASI

### 1.1 Latar Belakang Masalah
Indonesia merupakan salah satu produsen kopi terbesar di dunia dengan keragaman varietas dan daerah asal yang sangat kaya, mulai dari Arabika Gayo di Aceh Tengah, Arabika Toraja di Sulawesi Selatan, Arabika Kintamani di Bali, hingga Robusta Lampung. Keragaman ini menjadi nilai jual yang besar di pasar internasional. Namun, rantai pasok kopi Nusantara dari kebun hingga bursa ekspor masih menghadapi sejumlah persoalan:
1. Ketiadaan jejak asal-usul (*traceability*). Pembeli internasional sulit memverifikasi asal kebun, varietas, dan proses pascapanen sebuah batch kopi.
2. Penilaian mutu yang manual dan subjektif. Deteksi cacat biji seperti *black bean*, *sour/moldy*, dan *broken*, serta penilaian cupping score masih sangat bergantung pada keahlian individu dan membutuhkan waktu.
3. Informasi kebun yang tidak terintegrasi. Petani kerap tidak mengetahui perkiraan cuaca yang memengaruhi proses penjemuran, sementara kemiringan lahan dan lokasi kebun belum terdokumentasi secara digital.
4. Kebutuhan konversi finansial dan lintas waktu. Harga kopi di pasar global seperti bursa ICE Futures Europe di London dipantau dalam beberapa mata uang (IDR, USD, GBP, EUR) dan zona waktu yang berbeda (WIB, WITA, WIT).
5. Risiko kerusakan selama pengiriman. Guncangan pada kontainer selama transit tidak tercatat, sehingga sulit menelusuri penyebab penurunan mutu ketika batch tiba di tujuan.

Berdasarkan permasalahan tersebut, tim pengembang merancang dan mengimplementasikan aplikasi **BeanOrigin**, sebuah platform mobile multi-role yang menghubungkan seluruh ekosistem rantai pasok kopi Indonesia. Aplikasi ini mengintegrasikan basis data offline-first (Hive dan Supabase), kecerdasan buatan berbasis Computer Vision untuk klasifikasi cacat biji, LLM Google Gemini sebagai penasihat roasting dan ekspor, Location-Based Services (LBS) untuk pemetaan kebun dan rute kontainer, sensor accelerometer dan gyroscope, konverter mata uang dan zona waktu, serta blockchain hash-chain sederhana untuk verifikasi keaslian batch.

### 1.2 Tema & Filosofi Desain Aplikasi BeanOrigin
Aplikasi BeanOrigin mengusung filosofi **“Dari Kebun ke Cangkir”**: setiap biji kopi memiliki cerita asal-usul, dan setiap cerita tersebut dapat diverifikasi oleh siapa pun yang membutuhkannya. Filosofi ini diterjemahkan ke dalam tiga pilar utama:
- **Transparansi**, diwujudkan melalui hash-chain yang membuat riwayat batch tidak dapat diubah secara diam-diam.
- **Keberpihakan pada petani**, diwujudkan melalui peran Petani yang sederhana, fitur cuaca kebun, serta arsitektur offline-first agar pencatatan tetap berjalan di lahan dengan sinyal terbatas.
- **Kejelasan informasi**, diwujudkan melalui dashboard yang beradaptasi dengan peran pengguna serta tata letak yang mengikuti kaidah ergonomi satu tangan.

Identitas visual BeanOrigin menggunakan tema kopi Nusantara: latar belakang warm dark `#140D05`, kartu `#28170B`, garis pembatas `#3D2E22`, aksen emas `#C0A85C`, hijau kebun `#4CAF50` untuk status verified, dan teks berbobot kontras tinggi untuk keterbacaan optimal di bawah sinar matahari perkebunan.

### 1.3 Landasan Teori Komprehensif
#### 1.3.1 Framework Flutter dan Bahasa Dart
Flutter adalah SDK pengembangan aplikasi lintas platform Google yang merender seluruh antarmuka secara mandiri melalui mesin grafis Impeller/Skia. Bahasa Dart mendukung kompilasi Ahead-of-Time (AOT) untuk performa native 60 fps. Manajemen state menggunakan pola Bloc/Cubit untuk memisahkan logika bisnis dari antarmuka, sedangkan navigasi dikelola terpusat melalui `AppRouter` (`onGenerateRoute`).

#### 1.3.2 Basis Data Lokal Hive dan Online Supabase
Hive adalah basis data NoSQL ringan berbasis box biner yang berjalan langsung di memori perangkat. Digunakan untuk menyimpan cache rekomendasi Gemini, data batch offline, pengaturan biometrik, riwayat forum, dan blok blockchain lokal. Supabase (PostgreSQL) digunakan sebagai backend sinkronisasi komoditas cloud.

#### 1.3.3 Keamanan Data, Hashing SHA-256, JWT, dan Biometrik
- **Hashing SHA-256**: Kata sandi di-hash di sisi klien sebelum dikirim, menghasilkan digest heksadesimal 64 karakter.
- **JSON Web Token (JWT)**: Sesi berlaku selama 3 jam, setelah itu aplikasi auto-logout.
- **flutter_secure_storage**: Penyimpanan token terenkripsi hardware (Android Keystore).
- **local_auth**: Otentikasi biometrik sidik jari native perangkat.

#### 1.3.4 Integrasi Web Service & RESTful API
- **Frankfurter API**: Kurs realtime IDR, USD, GBP, dan EUR berbasis European Central Bank.
- **Open-Meteo API**: Data suhu udara, kelembapan, curah hujan, dan ramalan 7 hari gratis tanpa API key.
- **Google Gemini 1.5 Flash API**: Rekomendasi profil roasting dan kepatuhan ekspor standar SCAA/SNI.

#### 1.3.5 Location-Based Services (LBS) & Peta OpenStreetMap
Sensor GPS (`geolocator`) mengambil koordinat kebun saat panen dicatat. Peta interaktif `flutter_map` (OpenStreetMap) menampilkan sebaran kebun kopi dan rute polyline pengiriman kontainer menuju 7 pelabuhan ekspor Indonesia.

#### 1.3.6 Pemanfaatan Sensor Perangkat
- **Accelerometer**: Cargo Shock Monitor mendeteksi benturan transit (>2.0G). Fitur *Shake to Random Inspect* mengocok sampel karung acak.
- **Gyroscope**: Clinometer (waterpass digital) mengukur kemiringan lereng lahan dan rak penjemuran.

#### 1.3.7 Computer Vision On-Device (TFLite)
Model transfer learning MobileNetV2 mengklasifikasikan 6 kelas kondisi biji kopi (Normal Bean, Black Bean, Sour Bean, Broken Bean, Unripe Bean, Insect Damage) langsung di perangkat.

#### 1.3.8 Blockchain Hash-Chain & QR Code
Buku besar lokal berbasis rantai blok kriptografis SHA-256. Setiap batch terverifikasi mengikat hash blok sebelumnya, menghasilkan sertifikat QR yang dapat divalidasi keasliannya oleh pembeli internasional.

#### 1.3.9 Notifikasi Lokal Terjadwal
Pustaka `flutter_local_notifications` mengirimkan alarm pembukaan bursa lelang London ICE Futures, alert fluktuasi kurs valas > 1%, dan peringatan hujan lebat kebun.

#### 1.3.10 Ergonomi Mobile & Hukum “Mobile Thumb Zone”
Mengikuti kaidah Steven Hoober: area atas (25% glance only), tengah (35% easy reach), dan bawah (40% thumb touch). Tombol aksi dan navigasi dipusatkan pada area bawah layar dengan target sentuh minimal 44 x 44 dp.

---

# BAB II  
# PERANCANGAN SISTEM

### 2.1 Analisis Kebutuhan Perangkat Lunak (SRS)
#### 2.1.1 Kebutuhan Fungsional (Functional Requirements)

| No | Kode FR | Deskripsi Kebutuhan Fungsional | Modul Terkait |
|:---:|:---:|:---|:---:|
| 1 | FR-01 | Pengguna dapat mendaftar dan masuk menggunakan email dan password yang di-hash SHA-256. | Autentikasi |
| 2 | FR-02 | Pengguna dapat masuk menggunakan sensor biometrik (sidik jari / Face ID). | Autentikasi |
| 3 | FR-03 | Pengguna dapat mengakhiri sesi (logout) dengan dialog konfirmasi. | Sesi |
| 4 | FR-04 | Sesi JWT berlaku 3 jam; setelah itu aplikasi melakukan auto-logout. | Sesi |
| 5 | FR-05 | Dashboard Home menampilkan konten adaptif berbasis peran: Petani, Q-Grader, Eksportir, Admin (RBAC). | Dashboard |
| 6 | FR-06 | Petani dapat menambah, melihat, mengubah, dan menghapus (CRUD) batch kopi saat offline. | Manajemen Batch |
| 7 | FR-07 | Pengguna dapat mencari dan memfilter batch kopi dengan search bar ber-debounce. | Pencarian |
| 8 | FR-08 | Petani dapat men-geo-tag lokasi kebun menggunakan GPS dan melihatnya di OpenStreetMap. | LBS |
| 9 | FR-09 | Sistem menampilkan cuaca kebun realtime dan mengirim alert hujan dari Open-Meteo. | Cuaca Kebun |
| 10 | FR-10 | Q-Grader dapat memindai biji kopi dengan AI Vision untuk menghitung persentase cacat. | AI Vision |
| 11 | FR-11 | Q-Grader dapat memvalidasi cupping score SCA dan mengubah status batch menjadi verified. | Kurasi Mutu |
| 12 | FR-12 | Pengguna dapat berkonsultasi mengenai roasting profile dan checklist ekspor ke Gemini AI. | AI Advisory |
| 13 | FR-13 | Pengguna dapat mengonversi nilai tukar IDR, USD, GBP, dan EUR secara realtime (Frankfurter). | Konverter Finansial |
| 14 | FR-14 | Pengguna dapat membandingkan 4 zona waktu (WIB, WITA, WIT, London) dan countdown jam lelang ICE. | Konverter Waktu |
| 15 | FR-15 | Sistem mendeteksi guncangan kargo >2G (Accelerometer) dan interaksi kocok HP (Shake-to-Inspect). | Sensor |
| 16 | FR-16 | Sistem menampilkan clinometer visual waterpass (Gyroscope) pengukur sudut lahan. | Sensor |
| 17 | FR-17 | Sistem menyimpan batch terverifikasi ke blok hash-chain dan mencetak sertifikat QR Code. | Blockchain |
| 18 | FR-18 | Pembeli dapat memindai QR Code untuk memvalidasi keutuhan hash-chain tanpa login. | Blockchain |
| 19 | FR-19 | Pengguna dapat memainkan mini game BeanSorter Blitz (Endless Survival Mode) beredukasi defect. | Gamifikasi |
| 20 | FR-20 | Sistem mengirim notifikasi lokal terjadwal: alarm lelang, alert valas, dan status batch. | Notifikasi |
| 21 | FR-21 | Pengguna dapat memberi evaluasi kuliah PaM dan saran rantai pasok (Dual-Tab) tersimpan di Hive. | Saran & Kesan |
| 22 | FR-22 | Pengguna dapat memperbarui foto profil dari kamera/galeri dan menguji modul biometrik. | Profil |

#### 2.1.2 Kebutuhan Non-Fungsional (Non-Functional Requirements)
- **Kinerja**: Waktu kueri Hive < 10 ms; rendering UI 60 fps stabil.
- **Keamanan**: Hash kata sandi SHA-256 di sisi klien; JWT tersimpan di Android Keystore.
- **Keandalan**: Arsitektur offline-first menjamin pencatatan batch tetap berjalan tanpa jaringan.
- **Konsistensi**: Rantai blok diverifikasi ulang setiap kali dibuka; manipulasi data langsung terdeteksi.
- **Ergonomi**: Memenuhi hukum *Mobile Thumb Zone* dengan target sentuh minimal 44 x 44 dp.

### 2.2 Use Case Diagram
Sistem menghubungkan empat aktor internal (Petani, Q-Grader, Eksportir, Admin), satu aktor publik (Pembeli), serta layanan eksternal (Frankfurter, Open-Meteo, Gemini, OpenStreetMap).

### 2.3 Deskripsi Use Case & Skenario
Mencakup skenario normal dan alternatif untuk: Registrasi & Login, Login Biometrik, Kelola Batch Kopi, Pantau Cuaca Kebun, Pindai Defect AI, Verifikasi Mutu SCA, AI Roasting Advisory, Konversi Kurs & Waktu, Cek QR Blockchain, serta Logout.

### 2.4 Activity Diagram
- **2.4.1 Registrasi, Login, dan Autentikasi Biometrik**: Alur validasi sesi 3 jam, login email SHA-256, dan fallback biometrik native.
- **2.4.2 Pindai Defect Biji Kopi (AI Vision)**: Alur kamera laboratorium, preprocessing, inferensi on-device MobileNetV2, dan pengisian persentase cacat.
- **2.4.3 Tambah Batch Panen & Geo-tag LBS**: Alur izin GPS, pencatatan koordinat kebun, kemiringan lereng (gyro), dan penyimpanan offline-first di Hive.
- **2.4.4 AI Roasting & Export Advisory (Gemini API)**: Alur konsultasi cerdas, pengecekan cache key lokal, request prompt ke Google Gemini, dan rendering rekomendasi sangrai serta checklist ekspor.
- **2.4.5 Cek Keaslian Batch via QR Code Blockchain**: Alur pemindaian QR oleh pembeli tanpa login, pembacaan blok Hive, validasi hash SHA-256 berantai, dan penerbitan sertifikat digital.
- **2.4.6 Pemantauan Cuaca Kebun & Notifikasi Hujan (Open-Meteo)**: Alur pembacaan GPS kebun, fetch data meteorologi Open-Meteo, evaluasi ambang hujan > 10 mm, dan trigger alarm jemuran kopi.
- **2.4.7 Monitoring Guncangan Kargo (Accelerometer & Gyroscope)**: Alur deteksi benturan transit > 2.0G, pencatatan shock event, interaksi kocok HP (Shake to Inspect), dan clinometer waterpass.
- **2.4.8 Konverter Valas Realtime & Jam Lelang Komoditas**: Alur pembacaan kurs Frankfurter API (EUR/USD/GBP/IDR) dan countdown pembukaan bursa lelang ICE London.
- **2.4.9 Mini Game Edukasi BeanSorter Blitz (Endless Survival Mode)**: Alur loop konveyor biji jatuh, penanganan tap biji cacat/bagus/emas, combo recovery nyawa, dan fakta edukatif cacat biji.
- **2.4.10 Modul Saran & Kesan (Dual-Tab System)**: Alur pengisian evaluasi perkuliahan PaM (rating & saran dosen) serta forum aspirasi ekosistem kopi yang tersimpan di Hive.

### 2.5 Sequence Diagram
- **2.5.1 Login Email dan Biometrik Native**
- **2.5.2 AI Roasting & Export Advisory dengan Caching Hive**
- **2.5.3 Verifikasi Keaslian Batch melalui QR Code Hash-Chain**
- **2.5.4 Pemindaian Defect AI on-Device & Verifikasi Mutu SCA**
- **2.5.5 Perekaman Sensor Accelerometer & Guncangan Kargo**

### 2.6 Arsitektur Sistem
Lapisan sistem terbagi menjadi: UI Layer (Screens & Widgets), State Management (Bloc/Cubit), Service Layer (API & Hardware Sensors), Penyimpanan Lokal (Hive & SecureStorage), dan Penyimpanan Cloud (Supabase).

### 2.7 Class Diagram (Diagram Kelas)
Struktur entitas data utama mencakup: `UserModel`, `CoffeeBatch`, `BeanBlock`, `CurrentWeather`, `DailyForecast`, dan `FeedbackModel`.

### 2.8 Perancangan Antarmuka Pengguna (Wireframe & Mockup)
Perancangan antarmuka memprioritaskan tata letak satu tangan pada area bawah layar (*Mobile Thumb Zone*), dilengkapi kartu informatif bergradasi warna status.

---

# BAB III  
# IMPLEMENTASI DAN PENJELASAN SOURCE CODE DETAIL

### 3.1 Struktur Proyek (Feature-First Architecture)
```
lib/
├── core/                  # Router (AppRouter), Tema, Konstanta, Notifikasi
├── features/
│   ├── auth/              # Login, Register, Sesi Biometrik
│   ├── batch/             # CRUD Batch Kopi, Form Inspeksi, Detail Batch
│   ├── ai_scanner/        # Pemindai Kamera Defect On-Device
│   ├── llm_advisor/       # Konsultasi Ekspor Google Gemini AI
│   ├── blockchain/        # Hash-Chain SHA-256 & Sertifikat QR
│   ├── maps/              # OpenStreetMap LBS & Polyline Rute Pelabuhan
│   ├── sensor/            # Accelerometer Shock & Gyroscope Clinometer
│   ├── weather/           # Plantation Weather Open-Meteo
│   ├── market/            # Kurs Valas Frankfurter & Auction Clock London
│   ├── game/              # Mini Game BeanSorter Blitz Endless Survival
│   ├── feedback/          # Sistem Evaluasi Perkuliahan & Saran Dual-Tab
│   └── profile/           # Foto Profil Kamera & Uji Sensor Hardware
├── shared/                # Model Data Bersama & Widget Komponen
└── main.dart              # Entry Point & MultiBlocProvider
```

*(Sub-bab 3.2 s/d 3.7 memuat implementasi inti logika SHA-256, Hash-Chain, Accelerometer, Frankfurter, Open-Meteo, dan Gemini AI)*

### 3.8 Hasil Tampilan Antarmuka dan Demonstrasi Fitur Aplikasi
- **3.8.1 Modul Autentikasi & Sensor Biometrik**: Screenshot halaman login dan dialog sidik jari native.
- **3.8.2 Dashboard Home Adaptif Berbasis Peran (RBAC)**: Screenshot 4 variasi kartu selamat datang dan highlight peran (Petani, Q-Grader, Eksportir, Admin).
- **3.8.3 Manajemen Batch Kopi & Pencarian dengan Debounce**: Screenshot daftar batch dan filter multikriteria.
- **3.8.4 Location-Based Services (LBS)**: Screenshot peta sebaran kebun kopi dan jalur polyline logistik ke pelabuhan ekspor.
- **3.8.5 Sensor Inersia**: Screenshot grafik guncangan G-Force Accelerometer dan bubble level waterpass Gyroscope.
- **3.8.6 AI Computer Vision**: Screenshot kamera pemindai defect dan hasil proporsi cacat biji kopi.
- **3.8.7 AI Roasting & Export Advisory**: Screenshot rekomendasi profil sangrai dan checklist regulasi ekspor dari Gemini AI.
- **3.8.8 Konverter Valas Realtime & Jam Lelang Komoditas**: Screenshot konverter mata uang dan countdown jam lelang London.
- **3.8.9 Plantation Weather Monitor**: Screenshot widget cuaca perkebunan dan prakiraan hujan 7 hari.
- **3.8.10 Blockchain Immutable Hash-Chain**: Screenshot sertifikat keaslian dan status verifikasi rantai hash.
- **3.8.11 Mini Game Edukasi BeanSorter Blitz**: Screenshot aksi gameplay Endless Survival Mode dan pop-up fakta defect.
- **3.8.12 Modul Saran & Kesan (Dual-Tab)**: Screenshot Tab Evaluasi Perkuliahan PaM dan Tab Forum Ekosistem Kopi.
- **3.8.13 Profil Pengguna & Uji Sensor**: Screenshot profil pengguna berfoto dan dialog uji modul biometrik.

---

# BAB IV  
# LEMBAR EVALUASI PENGUJIAN PERANGKAT LUNAK

### 4.1 Lingkungan Pengujian
- Perangkat: Emulator Android (Pixel 7 API 34) & Perangkat Fisik Android.
- OS: Android 13 / 14.
- Layanan Eksternal: Frankfurter API, Open-Meteo API, Gemini 1.5 Flash API, Supabase, OpenStreetMap.

### 4.2 Tabel Pengujian Black Box (TC-01 s/d TC-18)
Seluruh 18 skenario uji fungsional normal dan anomali (registrasi, login, sesi expired 3 jam, offline CRUD, GPS LBS, cuaca kebun, scanner AI, valas, jam lelang, accelerometer shock, cache Gemini, blockchain QR, mini game, dan logout) berstatus **Sesuai (100% Pass)**.

### 4.3 Evaluasi & Pembahasan Hasil Pengujian
Sistem terbukti andal dalam menjaga keamanan sesi pengguna, menjamin konsistensi data secara offline-first menggunakan Hive, mendeteksi manipulasi data melalui validasi SHA-256 blockchain, serta menyajikan antarmuka ergonomis tanpa kendala layout overflow.

---

# BAB V  
# KESIMPULAN DAN SARAN

### 5.1 Kesimpulan
1. BeanOrigin berhasil dibangun sebagai platform rantai pasok kopi digital multi-role yang memenuhi 100% dari 15 kriteria fungsional wajib tugas akhir Pemrograman Aplikasi Mobile ditambah 1 fitur bonus cuaca GPS kebun.
2. Penerapan arsitektur *Feature-First Clean Architecture* dan Bloc/Cubit menghasilkan kode yang modular, efisien, dan bebas memory leak.
3. Integrasi AI Computer Vision, Google Gemini LLM, LBS OpenStreetMap, Sensor Inersia, dan Blockchain Hash-Chain memberikan solusi nyata bagi transparansi dan penjaminan mutu komoditas kopi Nusantara.
4. Pengujian black box mengonfirmasi keandalan sistem dalam mode online maupun offline.

### 5.2 Saran
1. Melakukan fine-tuning model TensorFlow Lite dengan dataset fisik biji kopi yang lebih masif untuk akurasi optimal di berbagai pencahayaan.
2. Memperluas build target ke platform iOS (CoreLocation & Face ID).
3. Mengembangkan hash-chain lokal menuju smart contract desentralisasi publik (Polygon/Ethereum Layer-2) untuk transaksi lelang global.


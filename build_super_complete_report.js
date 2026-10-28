const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const sourceDocx = "C:\\Users\\LENOVO\\.gemini\\antigravity\\brain\\8519c58d-f9c5-4e42-a5d6-9ca44be1a403\\.user_uploaded\\media_1793148275328_d9f5acba.docx";
const finalDocx = path.join(__dirname, "Laporan_Tugas_Akhir_PaM_BeanOrigin_Final.docx");
const tempZip = path.join(process.env.TEMP, "report_super_temp.zip");
const tempDir = path.join(__dirname, "docx_unpacked");

console.log("Unpacking docx...");
if (fs.existsSync(tempDir)) fs.rmSync(tempDir, { recursive: true, force: true });
fs.copyFileSync(sourceDocx, tempZip);
execSync(`powershell -ExecutionPolicy Bypass -Command "$ProgressPreference = 'SilentlyContinue'; Expand-Archive -Path '${tempZip}' -DestinationPath '${tempDir}' -Force"`);
fs.unlinkSync(tempZip);

const docXmlPath = path.join(tempDir, "word", "document.xml");
let xml = fs.readFileSync(docXmlPath, "utf8");
console.log("Original document.xml loaded. Length:", xml.length);

// Helpers
function p(text, options = {}) {
  const {
    bold = false,
    italic = false,
    size = 24, // 12pt
    align = "both",
    after = 120,
    before = 0,
    line = 360,
    heading = null
  } = options;

  let pPr = `<w:pPr>`;
  if (heading) {
    pPr += `<w:pStyle w:val="${heading}"/><w:keepNext/>`;
  }
  pPr += `<w:spacing w:after="${after}" w:before="${before}" w:line="${line}"/>`;
  pPr += `<w:jc w:val="${align}"/>`;
  pPr += `</w:pPr>`;

  let rPr = `<w:rPr>`;
  rPr += `<w:rFonts w:ascii="Times New Roman" w:cs="Times New Roman" w:eastAsia="Times New Roman" w:hAnsi="Times New Roman"/>`;
  rPr += `<w:b w:val="${bold ? 'true' : 'false'}"/>`;
  rPr += `<w:bCs w:val="${bold ? 'true' : 'false'}"/>`;
  if (italic) {
    rPr += `<w:i w:val="true"/><w:iCs w:val="true"/>`;
  }
  rPr += `<w:sz w:val="${size}"/><w:szCs w:val="${size}"/>`;
  rPr += `</w:rPr>`;

  const escapedText = text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");

  return `<w:p>${pPr}<w:r>${rPr}<w:t xml:space="preserve">${escapedText}</w:t></w:r></w:p>`;
}

function heading2(title) {
  const escapedText = title.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  return `<w:p><w:pPr><w:pStyle w:val="Heading2"/><w:keepNext/><w:spacing w:after="120" w:before="240"/><w:jc w:val="left"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:cs="Times New Roman" w:eastAsia="Times New Roman" w:hAnsi="Times New Roman"/><w:b/><w:bCs/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr><w:t xml:space="preserve">${escapedText}</w:t></w:r></w:p>`;
}

function heading3(title) {
  const escapedText = title.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  return `<w:p><w:pPr><w:pStyle w:val="Heading3"/><w:keepNext/><w:spacing w:after="80" w:before="180"/><w:jc w:val="left"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:cs="Times New Roman" w:eastAsia="Times New Roman" w:hAnsi="Times New Roman"/><w:b/><w:bCs/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr><w:t xml:space="preserve">${escapedText}</w:t></w:r></w:p>`;
}

function tocLine(title, page, indent = 440) {
  const escapedTitle = title.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  return `<w:p><w:pPr><w:tabs><w:tab w:val="right" w:pos="9071" w:leader="dot"/></w:tabs><w:spacing w:after="90" w:line="300"/><w:ind w:left="${indent}" w:hanging="0"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:cs="Times New Roman" w:eastAsia="Times New Roman" w:hAnsi="Times New Roman"/><w:b w:val="false"/><w:bCs w:val="false"/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr><w:t xml:space="preserve">${escapedTitle}</w:t></w:r><w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:cs="Times New Roman" w:eastAsia="Times New Roman" w:hAnsi="Times New Roman"/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr><w:tab/><w:t xml:space="preserve">${page}</w:t></w:r></w:p>`;
}

function tocChapter(title, page) {
  const escapedTitle = title.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  return `<w:p><w:pPr><w:tabs><w:tab w:val="right" w:pos="9071" w:leader="dot"/></w:tabs><w:spacing w:after="90" w:before="90" w:line="300"/><w:ind w:left="0" w:hanging="0"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:cs="Times New Roman" w:eastAsia="Times New Roman" w:hAnsi="Times New Roman"/><w:b/><w:bCs/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr><w:t xml:space="preserve">${escapedTitle}</w:t></w:r><w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:cs="Times New Roman" w:eastAsia="Times New Roman" w:hAnsi="Times New Roman"/><w:b/><w:bCs/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr><w:tab/><w:t xml:space="preserve">${page}</w:t></w:r></w:p>`;
}

function diagramBox(diagramTitle, caption) {
  let res = "";
  res += `<w:p><w:pPr><w:spacing w:after="60" w:before="140" w:line="240"/><w:jc w:val="center"/><w:pBdr><w:top w:val="single" w:sz="6" w:space="8" w:color="6B4226"/><w:left w:val="single" w:sz="6" w:space="12" w:color="6B4226"/><w:bottom w:val="single" w:sz="6" w:space="8" w:color="6B4226"/><w:right w:val="single" w:sz="6" w:space="12" w:color="6B4226"/></w:pBdr><w:shd w:val="clear" w:color="auto" w:fill="FBF9F6"/></w:pPr>`;
  res += `<w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:b/><w:bCs/><w:color w:val="6B4226"/><w:sz w:val="20"/><w:szCs w:val="20"/></w:rPr><w:t xml:space="preserve">[DIAGRAM ALUR SISTEM UML]</w:t></w:r>`;
  res += `<w:r><w:br/><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:i/><w:iCs/><w:color w:val="4A3628"/><w:sz w:val="18"/><w:szCs w:val="18"/></w:rPr><w:t xml:space="preserve">${diagramTitle.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")}</w:t></w:r>`;
  res += `</w:p>`;
  res += p(caption, { bold: true, align: "center", after: 180, before: 60, size: 22 });
  return res;
}

function screenshotPlaceholder(title, caption) {
  let res = "";
  res += `<w:p><w:pPr><w:spacing w:after="60" w:before="140" w:line="240"/><w:jc w:val="center"/><w:pBdr><w:top w:val="single" w:sz="6" w:space="8" w:color="B0A8A0"/><w:left w:val="single" w:sz="6" w:space="12" w:color="B0A8A0"/><w:bottom w:val="single" w:sz="6" w:space="8" w:color="B0A8A0"/><w:right w:val="single" w:sz="6" w:space="12" w:color="B0A8A0"/></w:pBdr><w:shd w:val="clear" w:color="auto" w:fill="F5F3EF"/></w:pPr>`;
  res += `<w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:b/><w:bCs/><w:color w:val="6B4226"/><w:sz w:val="20"/><w:szCs w:val="20"/></w:rPr><w:t xml:space="preserve">[TEMPATKAN GAMBAR SCREENSHOT HASIL RUNNING DI SINI]</w:t></w:r>`;
  res += `<w:r><w:br/><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/><w:i/><w:iCs/><w:color w:val="706050"/><w:sz w:val="18"/><w:szCs w:val="18"/></w:rPr><w:t xml:space="preserve">${title.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")}</w:t></w:r>`;
  res += `</w:p>`;
  res += p(caption, { bold: true, align: "center", after: 180, before: 60, size: 22 });
  return res;
}

// -------------------------------------------------------------
// EXTENDED ACTIVITY DIAGRAMS (2.4.4 s/d 2.4.10)
// To be appended at the end of Section 2.4 (before 2.5 Sequence Diagram)
// -------------------------------------------------------------
let newActivityDiagrams = "";

newActivityDiagrams += heading3("2.4.4 AI Roasting & Export Advisory (Gemini API)");
newActivityDiagrams += p("Activity diagram berikut menggambarkan alur konsultasi penasihat cerdas menggunakan Google Gemini 1.5 Flash. Pengguna membuka Batch Detail dan menekan tombol AI Advisor. Sistem memeriksa memori cache lokal (Hive); apabila data sudah pernah di-generate, sistem mengembalikan hasil secara instan. Apabila belum ada (cache miss), sistem membaca metadata batch, menyusun prompt terstruktur, memanggil Gemini API, menyimpan respons ke cache, lalu merender kartu rekomendasi sangrai, cupping notes, dan checklist regulasi ekspor SNI/SCAA.");
newActivityDiagrams += diagramBox("Alur Pengecekan Cache Lokal -> Request Prompt Gemini API -> Penyimpanan Cache Hive", "Gambar 2.4.1 Activity Diagram AI Roasting & Export Advisory");

newActivityDiagrams += heading3("2.4.5 Cek Keaslian Batch via QR Code Blockchain");
newActivityDiagrams += p("Activity diagram berikut memodelkan alur verifikasi keaslian batch kopi oleh pihak pembeli internasional tanpa perlu login. Pembeli memindai QR Code pada kemasan menggunakan kamera. Sistem mengekstrak payload blok, membaca blok lokal di Hive, dan menghitung ulang hash SHA-256 setiap blok secara berantai. Apabila seluruh rantai hash valid dan tidak mengalami manipulasi, sistem menampilkan Sertifikat Keaslian Digital dengan status terverifikasi. Jika ada ketidakcocokan hash, sistem menampilkan status peringatan.");
newActivityDiagrams += diagramBox("Alur Pindai QR Code -> Ambil Blok Hive -> Hitung Ulang SHA-256 -> Tampilkan Sertifikat / Peringatan", "Gambar 2.4.2 Activity Diagram Cek Keaslian Batch via QR Code Blockchain");

newActivityDiagrams += heading3("2.4.6 Pemantauan Cuaca Kebun & Notifikasi Hujan (Open-Meteo)");
newActivityDiagrams += p("Activity diagram ini menggambarkan proses monitoring kondisi cuaca perkebunan kopi berbasis LBS. Sistem membaca koordinat latitude dan longitude kebun yang tersimpan pada batch, lalu mengirim permintaan HTTP GET ke Open-Meteo API. Data cuaca terkini (suhu, kelembapan, curah hujan) dan prakiraan 7 hari ditampilkan. Apabila curah hujan 3 hari ke depan diprakirakan melebihi 10 mm, sistem secara otomatis menjadwalkan notifikasi lokal untuk memperingatkan petani agar segera mengangkat jemuran biji kopi.");
newActivityDiagrams += diagramBox("Alur Baca Koordinat GPS -> Fetch Open-Meteo -> Evaluasi Ambang Hujan -> Notifikasi Lokal Pengingat Jemuran", "Gambar 2.4.3 Activity Diagram Pemantauan Cuaca Kebun dan Peringatan Hujan");

newActivityDiagrams += heading3("2.4.7 Monitoring Guncangan Kargo (Accelerometer & Gyroscope)");
newActivityDiagrams += p("Activity diagram ini memodelkan pembacaan sensor inersia selama logistik transit kontainer. Modul Accelerometer mendengarkan event percepatan inersia secara kontinu. Apabila nilai percepatan melebihi 2.0 G, sistem mencatat 'shock event' ke log batch kargo. Pengguna juga dapat mengguncang ponsel (Shake to Inspect) untuk memilih sampel karung secara acak. Sementara itu, sensor Gyroscope mengukur kemiringan lahan atau rak penjemuran dalam bentuk visual waterpass.");
newActivityDiagrams += diagramBox("Alur Stream Sensor Inersia -> Hitung G-Force -> Catat Log Benturan > 2G / Kocok HP Uji Acak", "Gambar 2.4.4 Activity Diagram Monitoring Sensor Guncangan Kargo");

newActivityDiagrams += heading3("2.4.8 Konverter Valas Realtime & Jam Lelang Komoditas London");
newActivityDiagrams += p("Activity diagram ini menggambarkan alur kerja modul finansial dan konverter waktu. Sistem mengambil data kurs valas dari Frankfurter API (EUR, USD, GBP, IDR) dan menghitung nilai konversi harga kopi per kilogram secara realtime. Pada modul waktu, sistem menghitung selisih zona waktu (WIB, WITA, WIT, London) dan menampilkan countdown pembukaan sesi perdagangan bursa ICE Futures Europe (pukul 10:00 waktu London).");
newActivityDiagrams += diagramBox("Alur Fetch Kurs Frankfurter -> Konversi Nilai 4 Valas -> Hitung Mundur Jam Lelang ICE London", "Gambar 2.4.5 Activity Diagram Konverter Valas dan Countdown Jam Lelang London");

newActivityDiagrams += heading3("2.4.9 Mini Game Edukasi: BeanSorter Blitz (Endless Survival Mode)");
newActivityDiagrams += p("Activity diagram ini memodelkan gameplay mini game BeanSorter Blitz. Sistem menginisialisasi 3 nyawa hati, skor 0, level 1, dan conveyor belt. Biji kopi berjatuhan dengan kecepatan yang meningkat bertahap (speed scaling). Biji bagus dibiarkan meluncur ke wadah ekspor (+5 poin); biji cacat harus di-tap sebelum mencapai dasar (+20 poin). Kemunculan Golden Bean memberikan +50 poin x level, dan combo x7 memulihkan 1 nyawa. Ketika nyawa habis, permainan selesai dan sistem menyajikan fakta edukatif seputar jenis cacat biji kopi.");
newActivityDiagrams += diagramBox("Alur Loop Permainan Konveyor -> Deteksi Tap Biji Bagus / Cacat / Emas -> Update Nyawa & Skor -> Game Over & Fakta Defect", "Gambar 2.4.6 Activity Diagram Mini Game BeanSorter Blitz Endless Survival");

newActivityDiagrams += heading3("2.4.10 Modul Saran & Kesan (Dual-Tab System)");
newActivityDiagrams += p("Activity diagram ini memodelkan pengisian evaluasi perkuliahan dan forum saran rantai pasok kopi. Pengguna membuka menu Saran & Kesan di bottom navigation bar. Pada Tab 1, pengguna mengisi rating 1-5 bintang, kesan, dan kritik pembelajaran untuk dosen pengampu (Bagus Muhammad Akbar, S.ST., M.Kom.). Pada Tab 2, pengguna memilih kategori topik dan menyampaikan aspirasi ekosistem kopi. Data yang disubmit divalidasi dan disimpan secara permanen pada basis data NoSQL Hive lokal.");
newActivityDiagrams += diagramBox("Alur Buka Layar Dual-Tab -> Input Evaluasi Kuliah PaM / Forum Kopi -> Simpan ke Hive Box", "Gambar 2.4.7 Activity Diagram Modul Saran & Kesan Dual-Tab");

// -------------------------------------------------------------
// Class Diagram 2.7 & Wireframe 2.8
// -------------------------------------------------------------
let sec27_28 = "";
sec27_28 += heading2("2.7 Class Diagram (Diagram Kelas)");
sec27_28 += p("Class diagram berikut menggambarkan struktur kelas model data utama pada aplikasi BeanOrigin beserta relasi dan tipe datanya. Diagram ini merepresentasikan bagaimana entitas pengguna (UserModel), batch kopi (CoffeeBatch), rantai blok (BeanBlock), kondisi cuaca (CurrentWeather & DailyForecast), serta umpan balik pengguna (FeedbackModel) saling berinteraksi di dalam memori dan basis data (Hive & Supabase).");
sec27_28 += p("Struktur entitas data utama BeanOrigin mencakup:", { bold: true, after: 60 });
sec27_28 += p("• UserModel: id (String), name (String), email (String), role (String [farmer, q_grader, exporter, admin]), avatarPath (String), biometricEnabled (bool). Memiliki metode toJson() dan fromJson() untuk serialisasi sesi pengguna.");
sec27_28 += p("• CoffeeBatch: id (String), variety (String), origin (String), elevationMasl (double), process (String), farmerName (String), slopeAngle (double?), latitude (double?), longitude (double?), cuppingScore (double?), gradeLabel (String), moistureContent (double?), weightKg (double?), status (String [pending, verified, exported, sold]), defectResult (String?), createdAt (DateTime), verifiedAt (DateTime?), exportedAt (DateTime?).");
sec27_28 += p("• BeanBlock: index (int), timestamp (String), batchData (Map<String, dynamic>), previousHash (String), hash (String). Memiliki metode computeHash() dan verifyChain() berbasis algoritma hashing SHA-256.");
sec27_28 += p("• CurrentWeather: temperature (double), humidity (int), precipitation (double), rain (double), weatherCode (int), windSpeed (double), fetchedAt (DateTime), isRaining (bool), description (String), agronomicTips (List<String>).");
sec27_28 += p("• DailyForecast: date (DateTime), tempMax (double), tempMin (double), precipitation (double), precipProbability (int), weatherCode (int).");
sec27_28 += p("• FeedbackModel: id (String), rating (int), kesan (String), saran (String), category (String [Kuliah PaM, Petani, Mutu SCA, Logistik, Finansial]), timestamp (DateTime).");
sec27_28 += p("Relasi antarentitas:", { bold: true, before: 60, after: 60 });
sec27_28 += p("Satu pengguna (UserModel) dapat mendaftarkan atau memverifikasi banyak batch kopi (1 to 0..* CoffeeBatch). Setiap CoffeeBatch yang telah berstatus verified akan dicatat ke dalam tepat satu BeanBlock (1 to 1) untuk menjamin kekekalan riwayatnya. Setiap CoffeeBatch memiliki relasi opsional dengan data cuaca kebun (CurrentWeather) yang menaungi 7 hari prakiraan (DailyForecast). Pengguna juga dapat memberikan banyak catatan umpan balik (FeedbackModel) yang disimpan pada basis data NoSQL Hive.");

sec27_28 += heading2("2.8 Perancangan Antarmuka Pengguna (Wireframe & Mockup)");
sec27_28 += p("Perancangan antarmuka BeanOrigin didasarkan pada prinsip ergonomi Mobile Thumb Zone (Hoober, 2017). Seluruh area sentuh interaktif seperti tombol aksi utama, Floating Action Button (+ Batch Baru), dan menu navigasi bawah ditempatkan pada zona jangkauan alami ibu jari (40% area bawah layar) dengan ukuran target sentuh minimal 44 x 44 dp guna kenyamanan penggunaan satu tangan di area perkebunan.");
sec27_28 += p("Desain antarmuka membagi layar menjadi 3 zona fungsional: area atas (glance only) untuk judul dan ringkasan peran pengguna; area tengah (easy reach) untuk visualisasi kartu batch, peta rute logistik, dan metrik cuaca; serta area bawah (thumb touch) untuk kontrol filter, tab navigasi, dan tombol aksi proses ekspor.");

// -------------------------------------------------------------
// Section 3.8
// -------------------------------------------------------------
let sec38 = "";
sec38 += heading2("3.8 Hasil Tampilan Antarmuka dan Demonstrasi Fitur Aplikasi");
sec38 += p("Sub-bab ini menyajikan dokumentasi hasil eksekusi program (running application) pada perangkat smartphone dan emulator Android untuk membuktikan bahwa seluruh modul telah terimplementasi dan berfungsi secara penuh.");

sec38 += heading3("3.8.1 Modul Autentikasi & Sensor Biometrik");
sec38 += p("Layar autentikasi mengimplementasikan sistem keamanan mandiri tanpa dependensi pihak ketiga. Pengguna dapat masuk menggunakan email dan password yang di-hash menggunakan SHA-256 sebelum diverifikasi. Apabila perangkat memiliki sensor sidik jari atau Face ID, sistem memunculkan prompt dialog native Android menggunakan pustaka local_auth untuk memulihkan sesi pengguna terakhir secara instan.");
sec38 += screenshotPlaceholder("Tangkapan layar halaman login dan dialog sensor sidik jari native Android", "Gambar 3.1 Antarmuka Layar Login Email (Kiri) dan Dialog Sensor Sidik Jari Native Android (Kanan)");

sec38 += heading3("3.8.2 Dashboard Home Adaptif Berbasis Peran (RBAC)");
sec38 += p("Halaman utama menyajikan antarmuka yang berubah secara dinamis menyesuaikan peran akun yang sedang aktif. Setiap peran memiliki kartu fokus operasional yang berbeda: Petani difokuskan pada GPS kebun dan cuaca; Q-Grader pada antrean mutu dan AI Scanner; Eksportir pada kargo siap kapal, live valas, dan bursa London; serta Admin pada audit ledger dan kuantitas suplai nasional.");
sec38 += screenshotPlaceholder("Tangkapan layar 4 variasi kartu selamat datang dan highlight peran pengguna", "Gambar 3.2 Tampilan Dashboard Home Adaptif: (a) Petani, (b) Q-Grader, (c) Eksportir, dan (d) Admin");

sec38 += heading3("3.8.3 Manajemen Batch Kopi & Pencarian dengan Debounce");
sec38 += p("Daftar batch kopi menampilkan ringkasan komoditas berupa nama varietas, daerah asal, elevasi kebun, kadar air, skor cupping SCA, dan badge status berwarna. Fitur pencarian dilengkapi mekanisme debounce 500 ms agar kueri penyaringan multikriteria tidak membebani kinerja rendering UI saat pengguna mengetik.");
sec38 += screenshotPlaceholder("Tangkapan layar daftar batch kopi dan pencarian debounce", "Gambar 3.3 Halaman Daftar Batch Kopi dengan Filter Pencarian Multikriteria");

sec38 += heading3("3.8.4 Location-Based Services (LBS): Pemetaan Kebun & Rute Pelabuhan Ekspor");
sec38 += p("Memanfaatkan sensor GPS bawaan perangkat (geolocator) dan peta OpenStreetMap (flutter_map), sistem menandai koordinat kebun petani secara presisi. Jalur polyline otomatis ditarik dari titik kebun menuju salah satu dari 7 pelabuhan ekspor komoditas utama Indonesia lengkap dengan estimasi jarak logistik dalam kilometer.");
sec38 += screenshotPlaceholder("Tangkapan layar peta sentra kopi OpenStreetMap dan polyline rute pelabuhan", "Gambar 3.4 Peta Interaktif Sebaran Kebun Kopi dan Jalur Polyline Logistik ke Pelabuhan Ekspor");

sec38 += heading3("3.8.5 Sensor Inersia: Cargo Shock Monitor & Gyroscope Clinometer");
sec38 += p("Accelerometer membaca percepatan gravitasi secara realtime. Jika terjadi benturan kargo di atas 2.0 G, sistem mencatat riwayat benturan (shock event). Tersedia pula interaksi kocok HP (Shake to Random Inspect) untuk memilih sampel karung secara acak. Sensor Gyroscope berfungsi sebagai clinometer visual (bubble level) pengukur sudut kemiringan lereng kebun dan rak penjemuran.");
sec38 += screenshotPlaceholder("Tangkapan layar monitor accelerometer kargo dan clinometer waterpass gyroscope", "Gambar 3.5 Monitoring Sensor: (a) Grafik G-Force Accelerometer dan (b) Bubble Level Gyroscope");

sec38 += heading3("3.8.6 AI Computer Vision: Klasifikasi Cacat Biji Kopi On-Device");
sec38 += p("Q-Grader dapat memotret sampel biji kopi dari meja uji laboratorium. Model visi komputer secara lokal (on-device) memproses citra untuk mendeteksi proporsi biji normal dan lima jenis cacat fisik utama (black bean, sour bean, broken bean, unripe bean, insect damage). Hasil deteksi langsung dikonversi menjadi persentase mutu pada form verifikasi.");
sec38 += screenshotPlaceholder("Tangkapan layar kamera pemindai defect AI dan hasil persentase mutu biji kopi", "Gambar 3.6 Antarmuka Pemindaian Kamera AI Scanner dan Hasil Proporsi Defect Biji Kopi");

sec38 += heading3("3.8.7 AI Roasting & Export Advisory (Google Gemini 1.5 Flash)");
sec38 += p("Modul penasihat cerdas mengintegrasikan Google Gemini 1.5 Flash API. Data agronomis batch digabungkan dengan kondisi cuaca kebun untuk menghasilkan tiga rekomendasi terstruktur: profil sangrai (roasting profile), deskripsi cita rasa (cupping notes), dan daftar periksa kepatuhan ekspor standar SCAA/SNI, yang di-cache di basis data Hive lokal.");
sec38 += screenshotPlaceholder("Tangkapan layar rekomendasi sangrai, cupping notes, dan checklist regulasi dari Gemini AI", "Gambar 3.7 Rekomendasi Roasting Profile dan Checklist Ekspor dari Google Gemini AI");

sec38 += heading3("3.8.8 Konverter Valas Realtime & Jam Lelang Komoditas London");
sec38 += p("Halaman Market Price menyediakan konverter mata uang yang terhubung dengan Frankfurter API (berbasis kurs Bank Sentral Eropa) untuk mata uang IDR, USD, GBP, dan EUR. Sementara itu, widget Auction Clock menampilkan jam analog digital 4 zona waktu (WIB, WITA, WIT, dan London) serta hitung mundur pembukaan bursa lelang kopi dunia ICE Futures Europe.");
sec38 += screenshotPlaceholder("Tangkapan layar konverter valas realtime dan countdown jam lelang London", "Gambar 3.8 (a) Konverter Finansial 4 Mata Uang dan (b) Countdown Jam Lelang ICE London");

sec38 += heading3("3.8.9 Plantation Weather Monitor (Open-Meteo API)");
sec38 += p("Memanfaatkan koordinat LBS kebun petani, sistem mengambil data cuaca dari Open-Meteo API secara realtime tanpa memerlukan API key. Informasi yang disajikan mencakup suhu udara, persentase kelembapan, curah hujan harian, dan prakiraan 7 hari ke depan lengkap dengan tips agronomis penjemuran.");
sec38 += screenshotPlaceholder("Tangkapan layar widget cuaca perkebunan dan prakiraan hujan 7 hari", "Gambar 3.9 Halaman Pemantau Cuaca Perkebunan dan Notifikasi Peringatan Hujan");

sec38 += heading3("3.8.10 Blockchain Immutable Hash-Chain & Sertifikat QR");
sec38 += p("Setiap batch kopi yang telah diverifikasi oleh Q-Grader dikunci ke dalam rantai blok (hash-chain) lokal menggunakan enkripsi SHA-256. Sistem menyediakan pemindai QR Code di mana pembeli internasional dapat memvalidasi keutuhan hash. Apabila data dimodifikasi secara ilegal, sistem memunculkan peringatan bahwa rantai hash terputus (tampered).");
sec38 += screenshotPlaceholder("Tangkapan layar sertifikat QR blockchain dan status verifikasi hash", "Gambar 3.10 (a) Sertifikat Keaslian Blockchain dan (b) Validasi Integritas Hash-Chain");

sec38 += heading3("3.8.11 Mini Game Edukasi: BeanSorter Blitz (Endless Survival Mode)");
sec38 += p("Mini game interaktif dibangun menggunakan kanvas sentuh Flutter. Mengusung konsep Endless Survival, pengguna bertugas memilah biji cacat dan membiarkan biji bagus meluncur ke wadah ekspor. Dilengkapi speed scaling, kemunculan Golden Bean (+50 poin), sistem nyawa hati, combo recovery, screen shake visual feedback, dan fakta edukatif cacat biji kopi.");
sec38 += screenshotPlaceholder("Tangkapan layar aksi mini game BeanSorter Blitz dan pop-up fakta edukasi defect", "Gambar 3.11 Permainan BeanSorter Blitz Mode Survival dan Pop-up Fakta Edukasi Defect");

sec38 += heading3("3.8.12 Modul Saran & Kesan (Dual-Tab System)");
sec38 += p("Halaman umpan balik dirancang dengan antarmuka dua tab terpisah: Tab 1 untuk evaluasi mata kuliah PaM (rating 1-5 bintang, kolom kesan mendalam, dan saran perbaikan pembelajaran bagi dosen pengampu Bagus Muhammad Akbar, S.ST., M.Kom.), serta Tab 2 untuk Forum Ekosistem Kopi dengan riwayat tersimpan di NoSQL Hive.");
sec38 += screenshotPlaceholder("Tangkapan layar form evaluasi kuliah PaM dan forum saran ekosistem kopi", "Gambar 3.12 Antarmuka Saran & Kesan: (a) Tab Evaluasi Perkuliahan PaM dan (b) Tab Forum Rantai Pasok");

sec38 += heading3("3.8.13 Profil Pengguna & Uji Sensor Biometrik");
sec38 += p("Layar profil memungkinkan pengguna memperbarui foto profil langsung dari kamera atau galeri perangkat. Pada layar ini pula pengguna dapat mengaktifkan atau menonaktifkan fitur sidik jari, melakukan uji coba modul sensor biometrik (hardware test), serta membuka dialog informasi proyek tugas akhir.");
sec38 += screenshotPlaceholder("Tangkapan layar profil pengguna dengan avatar kamera dan dialog pengujian sensor", "Gambar 3.13 Layar Profil Pengguna dengan Avatar Kamera dan Dialog Pengujian Biometrik");

// -------------------------------------------------------------
// BAB V
// -------------------------------------------------------------
let babV = "";
babV += `<w:p><w:pPr><w:pStyle w:val="Heading1"/><w:keepNext/><w:pageBreakBefore/><w:spacing w:after="240" w:before="0"/><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:cs="Times New Roman" w:eastAsia="Times New Roman" w:hAnsi="Times New Roman"/><w:b/><w:bCs/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr><w:t xml:space="preserve">BAB V</w:t></w:r></w:p>`;
babV += `<w:p><w:pPr><w:spacing w:after="240" w:before="0" w:line="360"/><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii="Times New Roman" w:cs="Times New Roman" w:eastAsia="Times New Roman" w:hAnsi="Times New Roman"/><w:b/><w:bCs/><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr><w:t xml:space="preserve">KESIMPULAN DAN SARAN</w:t></w:r></w:p>`;

babV += heading2("5.1 Kesimpulan");
babV += p("Berdasarkan hasil perancangan, implementasi, dan pengujian yang telah dilakukan pada proyek pengembangan aplikasi mobile BeanOrigin, dapat ditarik beberapa kesimpulan utama sebagai berikut:");
babV += p("1. Aplikasi BeanOrigin berhasil dibangun sebagai platform rantai pasok kopi digital multi-role (Petani, Q-Grader, Eksportir, dan Admin) yang mengintegrasikan 15 kriteria fungsional wajib mata kuliah Pemrograman Aplikasi Mobile ditambah 1 fitur bonus berbasis API cuaca pertanian.");
babV += p("2. Penerapan arsitektur Feature-First Clean Architecture dan manajemen state Bloc/Cubit menghasilkan struktur kode yang modular, mudah dipelihara, responsif, dan bebas dari kendala kebocoran memori.");
babV += p("3. Integrasi teknologi modern seperti Computer Vision on-device, Google Gemini LLM, Location-Based Services OpenStreetMap, Sensor Inersia, dan Blockchain Hash-Chain berhasil memberikan nilai tambah nyata dalam meningkatkan transparansi, penjaminan mutu, dan efisiensi logistik ekspor kopi Nusantara.");
babV += p("4. Pengujian black box membuktikan bahwa seluruh fungsionalitas aplikasi berjalan stabil pada lingkungan Android dengan tingkat keandalan tinggi, baik dalam mode daring (online) maupun luring (offline-first).");

babV += heading2("5.2 Saran");
babV += p("Demi pengembangan dan penyempurnaan sistem BeanOrigin di masa mendatang, disarankan beberapa hal berikut:");
babV += p("1. Melakukan pelatihan lanjutan (fine-tuning) model TensorFlow Lite menggunakan dataset biji kopi fisik yang lebih masif untuk meningkatkan akurasi klasifikasi cacat di kondisi pencahayaan rendah.");
babV += p("2. Mengoptimalkan konfigurasi arsitektur native iOS (Apple CoreLocation dan Face ID) agar aplikasi dapat didistribusikan secara resmi di Apple App Store.");
babV += p("3. Mengembangkan buku besar blockchain lokal saat ini menuju jaringan publik terdesentralisasi (seperti Polygon atau Ethereum Layer-2) untuk transaksi lelang komoditas skala global.");

// -------------------------------------------------------------
// SPLIT AND INSERT LOGIC
// -------------------------------------------------------------
const paragraphs = xml.match(/<w:p\b[^>]*>[\s\S]*?<\/w:p>/g);
console.log('Original paragraphs count:', paragraphs.length);

let idxTOC_24 = -1;
let idxTOC_26 = -1;
let idxTOC_37 = -1;
let idxTOC_43 = -1;
let idxBody_Sec25 = -1; // 2.5 Sequence Diagram
let idxBody_BAB3 = -1;
let idxBody_BAB4 = -1;

paragraphs.forEach((pText, i) => {
  const text = (pText.match(/<w:t\b[^>]*>([\s\S]*?)<\/w:t>/g) || [])
    .map(t => t.replace(/<[^>]+>/g, ''))
    .join('');
  
  if (i < 80) {
    if (text.includes("2.4 Activity Diagram")) idxTOC_24 = i;
    if (text.includes("2.6 Arsitektur Sistem")) idxTOC_26 = i;
    if (text.includes("3.7 AI Roasting")) idxTOC_37 = i;
    if (text.includes("4.3 Kesimpulan")) idxTOC_43 = i;
  } else {
    if (text.includes("2.5 Sequence Diagram") && idxBody_Sec25 === -1) idxBody_Sec25 = i;
    if (text.trim() === "BAB III" && idxBody_BAB3 === -1) idxBody_BAB3 = i;
    if (text.trim() === "BAB IV" && idxBody_BAB4 === -1) idxBody_BAB4 = i;
  }
});

console.log({ idxTOC_24, idxTOC_26, idxTOC_37, idxTOC_43, idxBody_Sec25, idxBody_BAB3, idxBody_BAB4 });

let newParagraphs = [];

for (let i = 0; i < paragraphs.length; i++) {
  newParagraphs.push(paragraphs[i]);

  // Insert in TOC: Activity Diagrams 2.4.4 s/d 2.4.10
  if (i === idxTOC_24) {
    newParagraphs.push(tocLine("2.4.4 AI Roasting &amp; Export Advisory (Gemini API)", "18", 660));
    newParagraphs.push(tocLine("2.4.5 Cek Keaslian Batch via QR Code Blockchain", "19", 660));
    newParagraphs.push(tocLine("2.4.6 Pemantauan Cuaca Kebun &amp; Notifikasi Hujan", "20", 660));
    newParagraphs.push(tocLine("2.4.7 Monitoring Guncangan Kargo (Accelerometer)", "21", 660));
    newParagraphs.push(tocLine("2.4.8 Konverter Valas &amp; Auction Clock London", "22", 660));
    newParagraphs.push(tocLine("2.4.9 Mini Game Edukasi BeanSorter Blitz", "23", 660));
    newParagraphs.push(tocLine("2.4.10 Modul Saran &amp; Kesan (Dual-Tab System)", "24", 660));
  }

  // Insert in TOC: 2.7, 2.8
  if (i === idxTOC_26) {
    newParagraphs.push(tocLine("2.7 Class Diagram", "27"));
    newParagraphs.push(tocLine("2.8 Perancangan Antarmuka Pengguna (Wireframe &amp; Mockup)", "28"));
  }

  // Insert in TOC: 3.8
  if (i === idxTOC_37) {
    newParagraphs.push(tocLine("3.8 Hasil Tampilan Antarmuka dan Demonstrasi Fitur Aplikasi", "32"));
  }

  // Insert in TOC: BAB V
  if (i === idxTOC_43) {
    newParagraphs.push(tocChapter("BAB V  KESIMPULAN DAN SARAN", "39"));
    newParagraphs.push(tocLine("5.1 Kesimpulan", "39"));
    newParagraphs.push(tocLine("5.2 Saran", "40"));
  }

  // Insert in Body: Activity Diagrams 2.4.4 s/d 2.4.10 right before 2.5 Sequence Diagram
  if (i === idxBody_Sec25 - 1) {
    newParagraphs.push(newActivityDiagrams);
  }

  // Insert in Body: 2.7 & 2.8 before BAB III
  if (i === idxBody_BAB3 - 1) {
    newParagraphs.push(sec27_28);
  }

  // Insert in Body: 3.8 before BAB IV
  if (i === idxBody_BAB4 - 1) {
    newParagraphs.push(sec38);
  }
}

// Insert BAB V at the end
newParagraphs.push(babV);

console.log('New paragraphs total:', newParagraphs.length);

const bodyStartIndex = xml.indexOf('<w:body>') + '<w:body>'.length;
const sectPrIndex = xml.lastIndexOf('<w:sectPr');
const xmlHeader = xml.slice(0, bodyStartIndex);
const xmlFooter = xml.slice(sectPrIndex);

const updatedXml = xmlHeader + newParagraphs.join('') + xmlFooter;
fs.writeFileSync(docXmlPath, updatedXml, 'utf8');

console.log("Successfully wrote super complete document.xml! Length:", updatedXml.length);

// Repack with PowerShell
const repackScript = `
$ProgressPreference = 'SilentlyContinue'
$finalZip = 'd:\\sem 5\\PaM\\tugas_akhir\\Laporan_Tugas_Akhir_PaM_BeanOrigin_Final.zip'
$finalDocx = 'd:\\sem 5\\PaM\\tugas_akhir\\Laporan_Tugas_Akhir_PaM_BeanOrigin_Final.docx'
if (Test-Path $finalZip) { Remove-Item $finalZip -Force }
if (Test-Path $finalDocx) { Remove-Item $finalDocx -Force }
Compress-Archive -Path '${tempDir}\\*' -DestinationPath $finalZip -Force
Rename-Item -Path $finalZip -NewName (Split-Path $finalDocx -Leaf)
Write-Output 'REPACK_SUCCESS'
`;
fs.writeFileSync(path.join(__dirname, 'repack_super.ps1'), repackScript, 'utf8');
execSync(`powershell -ExecutionPolicy Bypass -File "d:\\sem 5\\PaM\\tugas_akhir\\repack_super.ps1"`);
fs.unlinkSync(path.join(__dirname, 'repack_super.ps1'));
fs.rmSync(tempDir, { recursive: true, force: true });

console.log("DONE! File created at:", finalDocx);

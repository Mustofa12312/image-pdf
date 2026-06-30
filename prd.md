# PRD-001 — PDF ↔ Image Converter

**Versi:** 1.0
**Status:** Draft Final
**Platform:** Windows 10 & Windows 11 (64-bit)

---

# 1. Ringkasan

PDF ↔ Image Converter adalah aplikasi desktop Windows yang dirancang untuk mengubah **PDF menjadi PNG/JPG** dan **PNG/JPG menjadi PDF** dengan fokus pada:

- Sangat cepat
- Ringan
- Mudah digunakan
- Modern
- Offline (100% tanpa internet)

Aplikasi ini bukan editor PDF, melainkan utilitas konversi berkinerja tinggi.

---

# 2. Visi Produk

Menjadi aplikasi konversi PDF dan gambar yang:

- Lebih cepat dibanding aplikasi gratis lainnya.
- Ringan dijalankan bahkan pada komputer spesifikasi rendah.
- Memiliki antarmuka sederhana tanpa mengorbankan fitur penting.

---

# 3. Target Pengguna

- Mahasiswa
- Guru
- Pegawai kantor
- Percetakan
- Freelancer
- Desainer
- Pengguna umum

---

# 4. Tujuan Produk

Menyediakan solusi konversi PDF ↔ Image yang:

- Cepat
- Akurat
- Stabil
- Mudah digunakan
- Tanpa koneksi internet

---

# 5. Teknologi

## Frontend

- Flutter Desktop

## Backend

- Rust

## PDF Engine

- PDFium

## Image Engine

- image-rs

## Build

- Windows x64

---

# 6. Ruang Lingkup

## Fitur V1

✅ PDF → PNG

✅ PDF → JPG

✅ PNG → PDF

✅ JPG → PDF

Tidak termasuk:

- OCR
- Edit PDF
- Merge PDF
- Split PDF
- Compress PDF
- Watermark

---

# 7. Functional Requirements

## Modul A

### PDF → Image

Pengguna dapat:

- Drag & Drop PDF
- Browse File
- Preview halaman
- Memilih semua halaman
- Memilih halaman tertentu
- Mengubah ke PNG
- Mengubah ke JPG

---

### Pengaturan Output

Output:

- PNG
- JPG

DPI

- 72
- 150
- 300
- 600

JPG Quality

- 50%
- 70%
- 90%
- 100%

Output Folder

- Same Folder
- Custom Folder

Nama File

Contoh

```
document_page_001.png

document_page_002.png

document_page_003.png
```

---

## Modul B

### Image → PDF

Support

PNG

JPG

JPEG

Pengguna dapat:

- Drag gambar
- Drag banyak gambar
- Mengubah urutan
- Rotate gambar
- Menghapus gambar
- Preview

---

### Pengaturan PDF

Ukuran

- Original
- A4
- Letter

Orientasi

- Portrait

- Landscape

Margin

- None

- Small

- Medium

- Large

---

# 8. Non Functional Requirements

## Startup

< 2 detik

---

## RAM Idle

< 100 MB

---

## CPU

Idle

< 2%

---

## Installer

Target

< 30 MB

---

## Offline

100%

---

## Internet

Tidak diperlukan

---

## Multi Thread

Ya

PDF diproses paralel.

---

## Responsif

UI tidak boleh freeze.

---

# 9. UI

## Halaman Home

```
-----------------------------------

PDF ↔ IMAGE CONVERTER

-----------------------------------

[ PDF → IMAGE ]

[ IMAGE → PDF ]

-----------------------------------
```

---

## PDF → IMAGE

```
+--------------------------------+

Drop PDF Here

atau

Browse

+--------------------------------+

Preview

□ Halaman 1

□ Halaman 2

□ Halaman 3

Output

( ) PNG

( ) JPG

DPI

▼300

Quality

▼100%

Folder

Same Folder

Convert

```

---

## IMAGE → PDF

```
Drop Images

Preview

1

2

3

4

Move Up

Move Down

Rotate

Delete

Paper

A4

Orientation

Portrait

Save PDF

```

---

# 10. UX

Harus dapat digunakan hanya dalam:

PDF → PNG

3 klik

1. Pilih PDF

2. PNG

3. Convert

---

Image → PDF

3 klik

1. Pilih gambar

2. Save

3. Selesai

---

# 11. Error Handling

PDF rusak

```
Unable to read PDF.
```

Password PDF

```
PDF is password protected.
```

Folder tidak bisa ditulis

```
Output folder is not writable.
```

File sedang digunakan

```
File is currently in use.
```

---

# 12. Progress

```
Converting...

██████████░░░░

68%

5 / 8 Pages
```

---

# 13. Setelah Selesai

Menampilkan

```
Conversion Complete

8 Images Created

Open Folder

Done
```

---

# 14. Pengaturan

Theme

- Light

- Dark

Default DPI

Default JPG Quality

Remember Last Folder

Language

- Indonesia

- English

---

# 15. Struktur Project

```
lib/

presentation/

widgets/

pages/

controllers/

services/

models/

core/

rust/

assets/

windows/
```

---

# 16. Target Performa

PDF 10 halaman

< 3 detik

PDF 50 halaman

< 12 detik

PDF 100 halaman

< 25 detik

_(Target ini bergantung pada spesifikasi komputer dan kompleksitas isi PDF.)_

---

# 17. Keamanan

- Semua proses dilakukan secara lokal.
- Tidak ada pengiriman data ke server.
- Tidak ada akun pengguna.
- Tidak ada pelacakan (tracking).
- Tidak ada iklan.

---

# 18. Roadmap

## V1.0

- PDF → PNG
- PDF → JPG
- PNG → PDF
- JPG → PDF
- Drag & Drop
- Preview
- Multi-thread
- Dark Mode
- Bahasa Indonesia & Inggris

## V1.1

- Batch convert banyak PDF sekaligus.
- Drag & Drop folder.
- Shortcut keyboard.
- Opsi buka folder hasil otomatis.
- Pengaturan kualitas yang lebih rinci.

## V2.0

- Konversi melalui menu klik kanan Windows (Shell Extension).
- Dukungan pemrosesan folder secara massal.
- Antrean (queue) konversi dengan pause dan resume.
- Optimalisasi performa untuk file PDF berukuran sangat besar.

---

# 19. Definisi Selesai (Definition of Done)

Produk dianggap selesai jika memenuhi seluruh kriteria berikut:

- Seluruh fitur inti berjalan stabil.
- Tidak terjadi crash pada pengujian normal.
- Antarmuka responsif selama proses konversi.
- Konversi PDF ↔ PNG/JPG menghasilkan output yang akurat.
- Mendukung drag & drop.
- Berjalan tanpa koneksi internet.
- Memiliki installer Windows dan versi portable.
- Dokumentasi pengguna dan panduan instalasi tersedia.

Dokumen ini dapat dijadikan acuan utama untuk desain UI/UX, implementasi teknis, pengujian (QA), dan pengembangan fitur pada versi selanjutnya.

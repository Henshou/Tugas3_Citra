# Tugas 3 - Pemrosesan Citra Digital

Aplikasi GUI MATLAB untuk tiga pendekatan segmentasi pada spesifikasi Tugas 3 IF4073:

1. Segmentasi objek berbasis tepi dengan peta tepi dan hasil segmentasi tampil bersamaan.
2. Segmentasi klasik menggunakan **quadtree split and merge**.
3. Semantic segmentation CamVid menggunakan model CNN melalui Python.

## Menjalankan aplikasi

1. Buka folder proyek ini di MATLAB.
2. Pastikan Image Processing Toolbox tersedia.
3. Jalankan perintah berikut pada MATLAB Command Window:

   ```matlab
   main
   ```

4. Tekan **Pilih Citra Input**. Dialog file akan terbuka pada folder `data/bsds500_test_8`, yang memuat delapan citra uji BSDS500 yang disertakan.
5. Pilih bagian/metode, atur parameter bila diperlukan, lalu tekan **Jalankan**.

## Split and merge

Implementasi pada `src/splitmerge/splitMerge.m` menggunakan dua tahap:

### 1. Split dengan quadtree (divide and conquer)

Untuk setiap blok, dihitung simpangan baku intensitas grayscale:

\[
\sigma_R = \operatorname{std}(I_R)
\]

Blok dianggap homogen dan tidak dibagi lagi jika `sigma_R <= splitThreshold`. Jika belum homogen, blok dibagi menjadi empat subblok; apabila salah satu dimensi sudah terlalu kecil, pembagian dilakukan hanya pada dimensi yang masih memungkinkan. Pembagian berhenti ketika blok homogen atau tidak dapat dibagi tanpa melanggar `minSize`.

### 2. Merge region bertetangga

Setelah split, adjacency dihitung berdasarkan ketetanggaan 4-arah (atas, bawah, kiri, kanan). Dua region digabung jika jarak RMS antara rerata warna RGB ternormalisasi keduanya tidak melebihi `mergeThreshold`:

\[
D(A,B)=\sqrt{\frac{1}{3}\sum_{c\in\{R,G,B\}}
(\mu_{A,c}-\mu_{B,c})^2}
\]

Rerata warna diperbarui secara berbobot setiap kali dua region digabung. Penggabungan diulang sampai tidak ada pasangan tetangga yang memenuhi predikat. Citra grayscale diperlakukan sebagai RGB dengan tiga kanal bernilai sama.

### Parameter GUI

| Parameter | Nilai awal | Arti dan pengaruh |
|---|---:|---|
| Ukuran minimum region (`minSize`) | 8 px | Batas ukuran minimum sisi blok saat quadtree membelah. Nilai lebih besar mengurangi jumlah split. |
| Threshold split (`splitThreshold`) | 0.05 | Batas simpangan baku intensitas grayscale. Nilai lebih besar membuat lebih banyak blok dianggap homogen sehingga region setelah split cenderung lebih sedikit/besar. |
| Threshold merge (`mergeThreshold`) | 0.05 | Batas jarak RMS rerata RGB untuk region bertetangga. Nilai lebih besar membuat lebih banyak region digabung sehingga jumlah region akhir berkurang. |

Kedua threshold harus berada pada rentang `[0, 1]`. Panel GUI menampilkan jumlah region setelah split, jumlah region setelah merge, banyak penggabungan, parameter, dan waktu proses. Pada mode Split and Merge, panel visualisasi menampilkan citra asli, peta region setelah split, serta overlay hasil akhir setelah merge.

## Pengujian

Jalankan skrip berikut dari folder proyek di MATLAB:

```matlab
run('test/splitMergeTest.m')
```

Skrip memeriksa bahwa tersedia delapan file JPG di `data/bsds500_test_8`, menjalankan split and merge untuk masing-masing citra, menampilkan citra input / hasil split / hasil merge, dan mencetak tabel jumlah region serta waktu proses.

Parameter uji awal mengikuti nilai default GUI (`minSize=8`, `splitThreshold=0.05`, `mergeThreshold=0.05`). Ubah parameter pada skrip untuk menganalisis pengaruh threshold.

## Segmentasi berbasis tepi

Deteksi tepi bukan bagian layar terpisah. Saat memilih **Segmentasi Berbasis Tepi**,
GUI menampilkan citra asli, peta deteksi tepi, label hasil segmentasi, dan overlay
objek utama secara bersamaan. Pilih operator (Sobel, Prewitt, Roberts, Laplace,
LoG, atau Canny) dan sesuaikan parameter deteksi serta morfologi pada panel yang sama.

## Struktur proyek

- `main.m`: entry point GUI.
- `src/gui/`: tampilan (`Layout.m`), kontrol (`App.m`), dan service pemrosesan (`Service.m`).
- `src/edge/`: operator deteksi tepi dan segmentasi berbasis tepi.
- `src/splitmerge/splitMerge.m`: implementasi split and merge.
- `src/deeplearning/`: integrasi MATLAB-Python untuk semantic segmentation.
- `data/bsds500_test_8/`: delapan citra uji BSDS500.
- `test/`: skrip pengujian tiap bagian.

## Deep learning

Bagian semantic segmentation memerlukan Python dengan dependensi dalam `src/deeplearning/python/requirements.txt`, dataset CamVid yang sudah disiapkan sesuai struktur yang dibaca `dataset.py`, dan bobot model `.pth` hasil training. File bobot `.pth` tidak disertakan di repositori ini; latih model menggunakan `train.py` atau pilih bobot yang sudah tersedia melalui tombol **Pilih Bobot Model (.pth)** di GUI.

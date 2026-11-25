# Tugas 3 - Pemrosesan Citra Digital

## a. Nama dan deskripsi program

**Aplikasi Segmentasi Citra Digital** adalah aplikasi GUI MATLAB untuk mencoba tiga pendekatan segmentasi citra digital:

1. Segmentasi objek berbasis tepi, yang menampilkan peta tepi dan hasil segmentasi secara bersamaan.
2. Segmentasi klasik menggunakan **quadtree split and merge**.
3. Semantic segmentation pada citra jalan CamVid menggunakan model CNN DeepLabV3 melalui Python.

### Anggota kelompok

| Nama | NIM | Tugas |
|---|---:|---|
| Samuel Gerrard H. Girsang | 13523064 | Laporan, segmentasi berbasis tepi, deep learning |
| Nadhif Al Rozin | 13523076 | Laporan, GUI, split and merge |

## b. Dependensi

### MATLAB

- MATLAB dengan **Image Processing Toolbox**. Toolbox ini diperlukan untuk operasi citra, termasuk fungsi deteksi tepi MATLAB.
- Tidak ada toolbox MATLAB tambahan yang diperlukan untuk metode split and merge.

### Python (khusus semantic segmentation)

- Python 3 yang dapat dijalankan dari MATLAB sebagai perintah `python`.
- Library Python pada `src/deeplearning/python/requirements.txt`:
  - PyTorch (`torch >= 2.0`)
  - Torchvision (`torchvision >= 0.15`)
  - NumPy
  - Pillow
- File bobot model PyTorch (`.pth`). Pilih file bobot melalui tombol **Pilih Bobot Model (.pth)** di GUI. GPU/CUDA bersifat opsional; tanpa GPU, inferensi berjalan menggunakan CPU.
- Dataset CamVid tidak diperlukan untuk menjalankan inferensi apabila bobot `.pth` sudah tersedia. Dataset diperlukan jika model hendak dilatih menggunakan `train.py`; siapkan folder `train`, `train_labels`, `val`, `val_labels`, `test`, dan `test_labels` sesuai format yang dibaca `dataset.py`.

Pasang library Python dengan menjalankan perintah berikut di terminal pada folder proyek:

```bash
python -m pip install -r src/deeplearning/python/requirements.txt
```

## c. Tata cara menjalankan program

1. Buka folder `Tugas3_Citra` sebagai folder kerja di MATLAB.
2. Pastikan MATLAB dan Image Processing Toolbox tersedia. Untuk menggunakan semantic segmentation, pastikan Python dan dependensinya sudah terpasang seperti dijelaskan pada bagian **Dependensi**.
3. Pada MATLAB Command Window, jalankan:

   ```matlab
   main
   ```

4. Di GUI, tekan **Pilih Citra Input**. Dialog akan terbuka pada `data/bsds500_test_8`, yang berisi delapan citra uji BSDS500; citra lain yang didukung juga dapat dipilih.
5. Pilih kategori dan metode segmentasi, lalu atur parameter bila diperlukan.
6. Untuk semantic segmentation, tekan **Pilih Bobot Model (.pth)** dan pilih bobot model yang sesuai.
7. Tekan **Jalankan** untuk memproses citra. Hasil ditampilkan di panel visualisasi GUI.

Metode berbasis tepi dan split and merge dapat dijalankan tanpa setup Python maupun bobot model.

Untuk melatih model, jalankan `train.py` dengan argumen `--data_dir` yang menunjuk ke folder dataset CamVid. Skrip akan menyimpan bobot model `.pth`; pilih bobot tersebut di GUI untuk melakukan inferensi.
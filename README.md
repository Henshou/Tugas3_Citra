# Tugas3_Citra

GUI MATLAB untuk:
- deteksi tepi (Sobel, Prewitt, Canny, Laplacian, dan Roberts);
- split and merge menggunakan quadtree;
- segmentasi semantik dengan model MATLAB `.mat` atau jaringan ONNX `.onnx`.

## Menjalankan GUI

Di Command Window MATLAB:

```matlab
cd('c:\00_Nadhif\03_Kuliah\01_Kampus\07_Semester_7\Citra\Tugas3_Citra')
main
```

Kode GUI mengikuti pola MVC Tugas 1:
- `src/gui/Layout.m`: tampilan;
- `src/gui/App.m`: kontrol interaksi;
- `src/gui/Service.m`: pemrosesan citra.
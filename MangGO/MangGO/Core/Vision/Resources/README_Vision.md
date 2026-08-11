# Core/Vision/Resources

Tempat menaruh model Core ML.

## File yang ditunggu

`MangoDefect.mlpackage`

## Cara mendapatkannya

Dataset sumber: [mangotest/mango-defect-detectionv4](https://universe.roboflow.com/mangotest/mango-defect-detectionv4) (CC BY 4.0)

Versi yang ter-train sekarang memakai arsitektur **Roboflow 3.0 Object Detection (Fast)** yang khusus untuk hosted API — tidak punya jalur export Core ML. Perlu train ulang dulu:

1. Di Roboflow, train versi dataset yang sama sebagai **YOLOv11n** atau **RF-DETR-nano**
2. Export ke format CoreML
3. Taruh `.mlpackage` di folder ini
4. Buka blok implementasi di `CoreMLDefectDetector.swift` dan hapus baris `throw`

## Perhatian

Metrik model versi sekarang: mAP@50 **38.2%**, precision **43.6%**, recall **42.0%**, dataset **401 gambar**, **1 kelas** (`defect`).

Cukup untuk memvalidasi pipeline berjalan. **Tidak cukup** untuk mengkalibrasi threshold grading — jangan menyetel `GradingRules` berdasarkan output model versi ini.

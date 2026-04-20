# Deep Learning Accelerator (DLA) Engine

Proyek ini mengimplementasikan inti akselerator komputasi paralel berbasis matrix-multiply (MAC array) yang relevan untuk CNN klasik dan komponen GenAI (perkalian matriks besar). Implementasi ditargetkan ke alur RTL sampai layout (GDS) menggunakan OpenLane pada PDK GF180MCU.

## Ringkasan Apa Yang Sudah Dibuat

1. RTL DLA engine lengkap dari level PE sampai top-level engine.
2. Testbench SystemVerilog untuk semua blok utama dengan self-check hasil.
3. Script simulasi otomatis menggunakan Icarus Verilog.
4. Integrasi OpenLane untuk flow sintesis sampai signoff.
5. Pemisahan sumber:
   - `rtl/` berisi Verilog `.v` untuk alur utama synthesis/simulation.
   - `rtl_sv/` berisi snapshot SystemVerilog `.sv` sebagai referensi.

## Deep Learning Accelerator (DLA) Engine

## Rumus Dasar Module Desain RTL

Bagian ini menjelaskan persamaan matematis yang dipakai untuk menurunkan struktur RTL pada PE array, buffer, dan controller.

### 1) Persamaan Komputasi Inti (Matrix Multiply / GEMM)

Untuk setiap elemen output matriks C:

$$
C_{i,j} = \sum_{k=0}^{K-1} A_{i,k} \times B_{k,j}
$$

Rumus ini direalisasikan sebagai akumulasi bertahap di PE:

$$
acc_{i,j}^{(0)} = 0
$$

$$
acc_{i,j}^{(t+1)} = acc_{i,j}^{(t)} + A_{i,t} \times B_{t,j}, \quad t = 0,1,\dots,K-1
$$

$$
C_{i,j} = acc_{i,j}^{(K)}
$$

Mapping ke RTL:
- Sinyal `clear` pada PE menerapkan $acc_{i,j}^{(0)} = 0$.
- Sinyal `en` pada PE menjalankan langkah rekurensi akumulasi untuk setiap siklus `t`.

### 2) Rumus Dataflow Output-Stationary

Dataflow yang dipakai adalah output-stationary, sehingga partial sum tetap di register PE selama iterasi `k`.

Pada siklus ke-`t`:

$$
a_i(t) = A_{i,t}, \quad b_j(t) = B_{t,j}
$$

$$
acc_{i,j}(t+1) = acc_{i,j}(t) + a_i(t)\,b_j(t)
$$

Konsekuensinya:
- Tidak perlu write-back partial sum ke memori eksternal setiap siklus.
- Trafik data berkurang karena hanya stream A/B yang bergerak, bukan hasil parsial C.

### 3) Rumus Addressing Buffer (Linearized Memory)

Pemetaan alamat linier yang dipakai pada bank buffer:

$$
addr_A(i,k) = i\cdot K + k
$$

$$
addr_B(k,j) = k\cdot N + j
$$

Saat `k_idx = t`, vektor yang dibaca ke PE array:

$$
row\_vector[i] = mem_A[addr_A(i,t)]
$$

$$
col\_vector[j] = mem_B[addr_B(t,j)]
$$

### 4) Rumus Packing/Unpacking Bus RTL

Pemetaan indeks bit yang digunakan:

$$
a\_in(i) = a\_bus[(i\cdot DATA\_W) +: DATA\_W]
$$

$$
b\_in(j) = b\_bus[(j\cdot DATA\_W) +: DATA\_W]
$$

$$
c\_bus[((i\cdot N + j)\cdot ACC\_W) +: ACC\_W] = acc_{i,j}
$$

Rumus ini adalah alasan kenapa RTL memakai flatten bus untuk antarmuka top-level dan tetap menjaga koneksi array PE yang deterministik.

### 5) Rumus Ukuran Lebar Sinyal

Lebar alamat minimal:

$$
ADDR\_W = \lceil \log_2(N\cdot K) \rceil
$$

$$
C\_ADDR\_W = \lceil \log_2(N\cdot N) \rceil
$$

$$
K\_IDX\_W = \lceil \log_2(K) \rceil
$$

Perkiraan lebar akumulator agar aman overflow untuk penjumlahan $K$ hasil perkalian signed:

$$
ACC\_W \ge 2\cdot DATA\_W + \lceil \log_2(K) \rceil
$$

Dengan default proyek ($DATA\_W=8, K=4$):

$$
ACC\_{min} = 2\cdot 8 + \lceil\log_2(4)\rceil = 18
$$

Implementasi memakai `ACC_W=24` untuk memberi headroom tambahan.

### 6) Rumus Throughput dan Siklus

Jumlah PE:

$$
PE\_count = N^2
$$

Jumlah MAC paralel per siklus compute:

$$
MAC/cycle = N^2
$$

Jumlah MAC total per transaksi matrix multiply:

$$
MAC\_{total} = N^2 \cdot K
$$

Urutan fase FSM controller:
- `CLEAR` selama 1 siklus.
- `COMPUTE` selama $K$ siklus.
- `DONE` sebagai fase selesai/handshake.

Untuk default $N=4, K=4$:

$$
MAC/cycle = 16, \quad MAC\_{total} = 64
$$

### 1) Processing Elements (PE) Array

Bagian yang sudah dibuat:
- `rtl/dla_pe.v`: 1 PE berisi operasi MAC signed (acc = acc + a*b), dengan reset, clear, dan enable.
- `rtl/dla_pe_array.v`: array PE ukuran `N x N` (default 4x4), berjalan paralel.

Makna terhadap topik:
- Ini adalah inti komputasi DLA.
- Arsitektur PE dapat dipakai untuk CNN (MAC convolution/GEMM), dan menjadi blok dasar akselerator matrix multiply untuk workload GenAI.
- Secara modular, PE juga dapat diganti dengan neuron model (misalnya LIF) bila ingin diarahkan ke SNN.

### 2) Dataflow Management

Bagian yang sudah dibuat:
- `rtl/dla_a_buffer_bank.v`: bank buffer untuk data A.
- `rtl/dla_b_buffer_bank.v`: bank buffer untuk data B.
- `rtl/dla_controller.v`: FSM kontrol fase clear, compute, done serta indeks `k`.
- `rtl/dla_engine_top.v`: integrasi controller + buffer + PE array, termasuk antarmuka write/read.

Dataflow yang diterapkan:
- **Output-stationary**: nilai keluaran (akumulator pada PE) ditahan di PE selama iterasi `k`, sedangkan data A/B di-stream dari buffer.
- Tujuan pendekatan ini adalah mengurangi perpindahan data hasil parsial dan menjaga efisiensi akses memori internal.

### 3) RTL-to-GDS Flow (OpenLane, GF180MCU)

Bagian yang sudah dibuat:
- Struktur desain OpenLane di `openlane/designs/dla_engine_top/`.
- Konfigurasi:
  - `openlane/designs/dla_engine_top/config.json`
  - `openlane/designs/dla_engine_top/config.tcl`
- Script utilitas:
  - `openlane/sync_sources.ps1` untuk sinkronisasi RTL ke folder OpenLane.
  - `openlane/run_openlane_docker.ps1` untuk menjalankan flow.

Status alur:
- Direktori run OpenLane dan hasil per tahap (`synthesis`, `floorplan`, `placement`, `routing`, `signoff`, `results/final`) sudah tersedia pada `openlane/designs/dla_engine_top/runs/...`.
- Ini menunjukkan alur digital implementation menuju layout sudah dijalankan pada node 180nm.

## Catatan Penting: Verilog vs SystemVerilog

- SystemVerilog **tidak hanya** untuk verifikasi; banyak fitur SV juga synthesizable untuk desain RTL.
- Untuk memastikan kompatibilitas alur Verilog klasik, proyek ini sekarang menyediakan:
  - `rtl/*.v` sebagai sumber utama.
  - `rtl_sv/*.sv` sebagai referensi versi SV sebelumnya.

## Struktur Folder Relevan

- `rtl/` : sumber Verilog `.v` (utama)
- `rtl_sv/` : sumber SystemVerilog `.sv` (arsip/referensi)
- `tb/` : testbench SystemVerilog
- `sim/` : script simulasi dan hasil run
- `openlane/` : integrasi flow OpenLane

## Cara Menjalankan Simulasi

```powershell
powershell -ExecutionPolicy Bypass -File .\sim\run_iverilog.ps1
```

Output artefak simulasi akan muncul di folder `sim/results/`.

## Cara Menjalankan OpenLane

1. Sinkronisasi sumber Verilog ke folder desain OpenLane:

```powershell
powershell -ExecutionPolicy Bypass -File .\openlane\sync_sources.ps1
```

2. Jalankan OpenLane (contoh mode classic):

```powershell
powershell -ExecutionPolicy Bypass -File .\openlane\run_openlane_docker.ps1 -Mode classic -PdkRoot "C:\Users\<user>\.volare"
```

## Arah Pengembangan Lanjut

1. Scale-up ukuran array (misalnya `N=8` atau lebih) dan evaluasi trade-off area/frekuensi.
2. Tambah mode dataflow lain (weight-stationary) untuk perbandingan performa/energi.
3. Tambah benchmark beban kerja (CNN layer/GEMM) untuk validasi throughput.
4. Eksperimen varian SNN dengan mengganti PE MAC ke neuron LIF.

/*
 * Tutorial CUDA - Perkalian Matriks
 * ================================================================
 * Dibuat oleh : I Wayan Aditya Swardiana
 * Email       : iway020@brin.go.id
 * ================================================================
 * Perkalian 2 matriks A (m x n) * B (n x o) = C (m x o)
 * Matriks direpresentasikan dalam row-major format
 * Dikompilasi dan dites pada CUDA 10.2 dan gcc 7.3.0 pada HPC BRIN
 * Kompilasi dengan perintah:
        $ module load cuda/10
        $ module load gcc/7
 *      $ nvcc perkalian-matriks.cu -o mat.o
 * Jalankan dengan perintah:
 *      $ module load cuda/10
 *      $ ./mat.o nilai_m nilai_n nilai_o
 */

#include <stdio.h>
#include <stdlib.h>

// kernel CUDA untuk perkalian matriks secara simpel
// 1 block mengerjakan 1 baris (m)
// tiap block memiliki thread sejumlah kolom (o)
// tiap thread menghitung perkalian matriks untuk baris m & kolom o
__global__ void gpu_perkalian_matriks_simpel(int *matriks_a, int *matriks_b, int *matriks_c, int m, int n, int o)
{
    int indeks_baris = blockIdx.x;
    int indeks_kolom = threadIdx.x;
    int jumlah = 0;

    if (indeks_baris < m && indeks_kolom < o)
    {
        for (int i = 0; i < n; i++)
        {
            jumlah += matriks_a[indeks_baris * n + i] * matriks_b[i * o + indeks_kolom];
        }
        matriks_c[indeks_baris * o + indeks_kolom] = jumlah;
    }
}

__global__ void gpu_perkalian_matriks_threadblock_2d(int *matriks_a, int *matriks_b, int *matriks_c, int m, int n, int o)
{

}

__global__ void gpu_perkalian_matriks_shared_memory(int *matriks_a, int *matriks_b, int *matriks_c, int m, int n, int o)
{

}

// fungsi untuk perkalian matriks secara simpel di CPU
void cpu_perkalian_matriks_simpel(int *matriks_a, int *matriks_b, int *matriks_c, int m, int n, int o)
{
    for (int indeks_baris = 0; indeks_baris < m; indeks_baris++)
    {
        for (int indeks_kolom = 0; indeks_kolom < o; indeks_kolom++)
        {
            int jumlah = 0;
            for (int i = 0; i < n; i++)
            {
                jumlah += matriks_a[indeks_baris * n + i] * matriks_b[i * o + indeks_kolom];
            }
            matriks_c[indeks_baris * o + indeks_kolom] = jumlah;
        }
    }
}

// fungsi untuk inisialisasi matriks secara random
void cpu_inisialisasi_matriks(int *matriks, int jumlah_baris, int jumlah_kolom)
{
    for (int indeks_baris = 0; indeks_baris < jumlah_baris; indeks_baris++)
    {
        for (int indeks_kolom = 0; indeks_kolom < jumlah_kolom; indeks_kolom++)
        {
            matriks[indeks_baris * jumlah_kolom + indeks_kolom] = rand() % 10;
        }
    }
}

// fungsi untuk mencetak matriks
void cpu_print_matriks(int *matriks, int jumlah_baris, int jumlah_kolom)
{
    for (int indeks_baris = 0; indeks_baris < jumlah_baris; indeks_baris++)
    {
        printf("[ ");
        for (int indeks_kolom = 0; indeks_kolom < jumlah_kolom; indeks_kolom++)
        {
            printf("%d ", matriks[indeks_baris * jumlah_kolom + indeks_kolom]);
        }
        printf("]\n");
    }
}

// fungsi untuk membandingkan hasil perkalian matriks di CPU & GPU
void cpu_validasi_hasil(int *matriks_cpu, int *matriks_gpu, int jumlah_baris, int jumlah_kolom)
{
    bool cek_hasil = true;
    for (int indeks_baris = 0; indeks_baris < jumlah_baris; indeks_baris++)
    {
        for (int indeks_kolom = 0; indeks_kolom < jumlah_kolom; indeks_kolom++)
        {
            if (matriks_cpu[indeks_baris * jumlah_kolom + indeks_kolom] != matriks_gpu[indeks_baris * jumlah_kolom + indeks_kolom])
            {
                cek_hasil = false;
            }
        }
    }

    if(cek_hasil)
    {
        printf("Hasil perkalian matriks di CPU dan GPU sama.\n");
    }
    else
    {
        printf("Hasil perkalian matriks di CPU dan GPU tidak sama.\n");
    }
}

int main(int argc, char const *argv[])
{
    // inisialisasi nilai m, n, dan o
    int m = atoi(argv[1]); 
    int n = atoi(argv[2]);
    int o = atoi(argv[3]);
   
    printf("PERKALIAN MATRIKS - MATRIKS A (%d x %d) * MATRIKS B (%d x %d)\n", m, n, n, o);
    printf("===============================\n");

    // inisialisasi matriks di host (CPU)
    int *host_matriks_a, *host_matriks_b, *host_matriks_c_cpu, *host_matriks_c_gpu;

    host_matriks_a = (int *) malloc (sizeof(int) * m * n);
    host_matriks_b = (int *) malloc (sizeof(int) * n * n);
    host_matriks_c_cpu = (int *) malloc (sizeof(int) * m * o);
    host_matriks_c_gpu = (int *) malloc (sizeof(int) * m * o);

    cpu_inisialisasi_matriks(host_matriks_a, m, n);
    cpu_inisialisasi_matriks(host_matriks_b, n, o);

    printf("Matriks A (%d x %d)\n", m, n);
    cpu_print_matriks(host_matriks_a, m, n);
    printf("===============================\n");
    printf("Matriks B (%d x %d)\n", n, o);
    cpu_print_matriks(host_matriks_b, n, o);
    printf("===============================\n");

    // eksekusi fungsi perkalian matriks di CPU
    cpu_perkalian_matriks_simpel(host_matriks_a, host_matriks_b, host_matriks_c_cpu, m, n, o);

    printf("Matriks C CPU (%d x %d)\n", m, o);
    cpu_print_matriks(host_matriks_c_cpu, m, o);
    printf("===============================\n");

    // inisialisasi matriks di device (GPU)
    int *device_matriks_a, *device_matriks_b, *device_matriks_c;

    cudaMalloc((void **) &device_matriks_a, sizeof(int) * m * n);
    cudaMalloc((void **) &device_matriks_b, sizeof(int) * n * o);
    cudaMalloc((void **) &device_matriks_c, sizeof(int) * m * o);

    // salin matriks input dari host ke device
    cudaMemcpy(device_matriks_a, host_matriks_a, sizeof(int) * m * n, cudaMemcpyHostToDevice);
    cudaMemcpy(device_matriks_b, host_matriks_b, sizeof(int) * n * o, cudaMemcpyHostToDevice);

    // inisialisasi thread block
    dim3 jumlah_block(m, 1, 1);
    dim3 jumlah_thread_per_block(o, 1, 1);

    // eksekusi kernel CUDA perkalian matriks di GPU
    gpu_perkalian_matriks_simpel<<<jumlah_block, jumlah_thread_per_block>>>(device_matriks_a, device_matriks_b, device_matriks_c, m, n, o);

    // salin matriks hasil dari device ke host
    cudaMemcpy(host_matriks_c_gpu, device_matriks_c, sizeof(int) * m * o, cudaMemcpyDeviceToHost);

    printf("Matriks C GPU (%d x %d)\n", m, o);
    cpu_print_matriks(host_matriks_c_gpu, m, o);
    printf("===============================\n");

    // cek hasil perkalian matriks
    cpu_validasi_hasil(host_matriks_c_cpu, host_matriks_c_gpu, m, o);
    
    // bersihkan memory device
    cudaFree(device_matriks_a);
    cudaFree(device_matriks_b);
    cudaFree(device_matriks_c);
}
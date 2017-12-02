### Hardware Platform

```
Architecture:          x86_64
CPU op-mode(s):        32-bit, 64-bit
Byte Order:            Little Endian
CPU(s):                36
On-line CPU(s) list:   0-35
Thread(s) per core:    2
Core(s) per socket:    9
Socket(s):             2
NUMA node(s):          2
Vendor ID:             GenuineIntel
CPU family:            6
Model:                 63
Model name:            Intel(R) Xeon(R) CPU E5-2666 v3 @ 2.90GHz
Stepping:              2
CPU MHz:               2900.000
CPU max MHz:           3500.0000
CPU min MHz:           1200.0000
BogoMIPS:              5876.39
Hypervisor vendor:     Xen
Virtualization type:   full
L1d cache:             32K
L1i cache:             32K
L2 cache:              256K
L3 cache:              25600K
NUMA node0 CPU(s):     0-8,18-26
NUMA node1 CPU(s):     9-17,27-35
```

aka: **AWS EC2 c4.8xlarge**


### Docker CLI args

each container was initialized as follows:

```
docker run -d --privileged --cpuset-cpus NN revolutionsystems/python:3.x.y-wee
```

The `c4.8xlarge` EC2 instance type has 18 dual-threaded cores. Each Python 
version’s test runs were executed on seperate CPU dies located on disparate NUMA
nodes.

The host was **not** reconfigured for kernel-level CPU isolation.

### Container Setup

Installed packages:

 * gcc
 * g++
 * gfortran
 * make
 * autoconf
 * automake
 * libtool

### (py)Performance CLI

```

python -m performance run --affinity NN -b all --append py3xy_(opt|nonopt).json

```

---

### Python 3.6.3 (pgo + lto)

| Benchmark              | unoptimized               | optimized                     |
|------------------------|---------------------------|-------------------------------|
| 2to3                   | 642 ms                    | 588 ms: 1.09x faster (-9%)    |
| chameleon              | 21.2 ms                   | 19.6 ms: 1.08x faster (-7%)   |
| chaos                  | 252 ms                    | 228 ms: 1.11x faster (-10%)   |
| crypto_pyaes           | 209 ms                    | 200 ms: 1.05x faster (-4%)    |
| deltablue              | 17.3 ms                   | 14.8 ms: 1.17x faster (-14%)  |
| django_template        | 321 ms                    | 282 ms: 1.14x faster (-12%)   |
| dulwich_log            | 158 ms                    | 140 ms: 1.13x faster (-11%)   |
| fannkuch               | 962 ms                    | 918 ms: 1.05x faster (-5%)    |
| float                  | 221 ms                    | 214 ms: 1.03x faster (-3%)    |
| genshi_text            | 67.1 ms                   | 61.5 ms: 1.09x faster (-8%)   |
| genshi_xml             | 140 ms                    | 127 ms: 1.10x faster (-9%)    |
| go                     | 565 ms                    | 488 ms: 1.16x faster (-14%)   |
| hexiom                 | 22.7 ms                   | 20.8 ms: 1.09x faster (-9%)   |
| html5lib               | 197 ms                    | 173 ms: 1.14x faster (-12%)   |
| json_dumps             | 23.3 ms                   | 21.6 ms: 1.08x faster (-7%)   |
| json_loads             | 50.0 us                   | 43.6 us: 1.15x faster (-13%)  |
| logging_format         | 25.4 us                   | 22.0 us: 1.15x faster (-13%)  |
| logging_silent         | 737 ns                    | 642 ns: 1.15x faster (-13%)   |
| logging_simple         | 21.3 us                   | 18.3 us: 1.16x faster (-14%)  |
| mako                   | 41.9 ms                   | 37.7 ms: 1.11x faster (-10%)  |
| meteor_contest         | 184 ms                    | 183 ms: 1.01x faster (-1%)    |
| nbody                  | 232 ms                    | 232 ms: 1.00x faster (-0%)    |
| nqueens                | 205 ms                    | 192 ms: 1.07x faster (-6%)    |
| pathlib                | 36.7 ms                   | 32.1 ms: 1.14x faster (-12%)  |
| pickle                 | 19.6 us                   | 17.1 us: 1.15x faster (-13%)  |
| pickle_dict            | 59.9 us                   | 50.1 us: 1.20x faster (-16%)  |
| pickle_list            | 8.12 us                   | 6.55 us: 1.24x faster (-19%)  |
| pickle_pure_python     | 1.10 ms                   | 946 us: 1.16x faster (-14%)   |
| pidigits               | 277 ms                    | 273 ms: 1.01x faster (-1%)    |
| python_startup         | 15.8 ms                   | 14.7 ms: 1.07x faster (-7%)   |
| python_startup_no_site | 9.51 ms                   | 8.94 ms: 1.06x faster (-6%)   |
| raytrace               | 1.24 sec                  | 1.09 sec: 1.14x faster (-12%) |
| regex_compile          | 389 ms                    | 355 ms: 1.10x faster (-9%)    |
| regex_dna              | 269 ms                    | 247 ms: 1.09x faster (-8%)    |
| regex_effbot           | 4.64 ms                   | 4.57 ms: 1.01x faster (-1%)   |
| regex_v8               | 41.9 ms                   | 39.7 ms: 1.06x faster (-5%)   |
| richards               | 176 ms                    | 147 ms: 1.20x faster (-17%)   |
| scimark_fft            | 616 ms                    | 602 ms: 1.02x faster (-2%)    |
| scimark_lu             | 477 ms                    | 452 ms: 1.06x faster (-5%)    |
| scimark_monte_carlo    | 221 ms                    | 204 ms: 1.08x faster (-8%)    |
| scimark_sor            | 464 ms                    | 411 ms: 1.13x faster (-11%)   |
| spectral_norm          | 253 ms                    | 240 ms: 1.05x faster (-5%)    |
| sqlalchemy_imperative  | 65.2 ms                   | 61.5 ms: 1.06x faster (-6%)   |
| sqlite_synth           | 6.09 us                   | 5.86 us: 1.04x faster (-4%)   |
| sympy_expand           | 903 ms                    | 836 ms: 1.08x faster (-7%)    |
| sympy_integrate        | 42.1 ms                   | 39.0 ms: 1.08x faster (-7%)   |
| sympy_sum              | 186 ms                    | 172 ms: 1.08x faster (-7%)    |
| sympy_str              | 401 ms                    | 368 ms: 1.09x faster (-8%)    |
| telco                  | 14.0 ms                   | 12.0 ms: 1.17x faster (-14%)  |
| tornado_http           | 411 ms                    | 377 ms: 1.09x faster (-8%)    |
| unpickle               | 31.6 us                   | 28.7 us: 1.10x faster (-9%)   |
| unpickle_list          | 7.07 us                   | 5.90 us: 1.20x faster (-16%)  |
| unpickle_pure_python   | 803 us                    | 711 us: 1.13x faster (-12%)   |
| xml_etree_parse        | 232 ms                    | 224 ms: 1.04x faster (-3%)    |
| xml_etree_iterparse    | 195 ms                    | 193 ms: 1.01x faster (-1%)    |
| xml_etree_generate     | 213 ms                    | 204 ms: 1.04x faster (-4%)    |
| xml_etree_process      | 175 ms                    | 164 ms: 1.07x faster (-6%)    |

Not significant: 

  * scimark_sparse_mat_mult
  * sqlalchemy_declarative 
  * unpack_sequence

---

### Python 3.5.4 (pgo + lto)

| Benchmark               | unoptimized  | optimized                     |
--------------------------|--------------|-------------------------------|
| 2to3                    | 652 ms       | 588 ms: 1.11x faster (-10%)   |
| chameleon               | 20.6 ms      | 17.9 ms: 1.15x faster (-13%)  |
| chaos                   | 260 ms       | 233 ms: 1.12x faster (-10%)   |
| crypto_pyaes            | 225 ms       | 208 ms: 1.08x faster (-8%)    |
| deltablue               | 16.4 ms      | 14.2 ms: 1.16x faster (-14%)  |
| django_template         | 316 ms       | 269 ms: 1.17x faster (-15%)   |
| dulwich_log             | 156 ms       | 138 ms: 1.13x faster (-12%)   |
| fannkuch                | 978 ms       | 946 ms: 1.03x faster (-3%)    |
| float                   | 233 ms       | 219 ms: 1.06x faster (-6%)    |
| genshi_text             | 66.6 ms      | 59.2 ms: 1.13x faster (-11%)  |
| genshi_xml              | 139 ms       | 122 ms: 1.14x faster (-12%)   |
| go                      | 535 ms       | 461 ms: 1.16x faster (-14%)   |
| hexiom                  | 22.7 ms      | 20.6 ms: 1.10x faster (-9%)   |
| html5lib                | 203 ms       | 173 ms: 1.17x faster (-14%)   |
| json_dumps              | 23.3 ms      | 21.2 ms: 1.10x faster (-9%)   |
| json_loads              | 48.9 us      | 42.2 us: 1.16x faster (-14%)  |
| logging_format          | 24.3 us      | 20.8 us: 1.17x faster (-14%)  |
| logging_silent          | 768 ns       | 675 ns: 1.14x faster (-12%)   |
| logging_simple          | 20.1 us      | 17.2 us: 1.17x faster (-14%)  |
| mako                    | 39.0 ms      | 35.4 ms: 1.10x faster (-9%)   |
| mdp                     | 5.76 sec     | 5.10 sec: 1.13x faster (-11%) |
| meteor_contest          | 194 ms       | 178 ms: 1.09x faster (-8%)    |
| nbody                   | 234 ms       | 222 ms: 1.06x faster (-5%)    |
| nqueens                 | 212 ms       | 194 ms: 1.09x faster (-8%)    |
| pathlib                 | 34.7 ms      | 30.1 ms: 1.15x faster (-13%)  |
| pickle                  | 20.5 us      | 17.5 us: 1.17x faster (-14%)  |
| pickle_dict             | 62.2 us      | 52.1 us: 1.19x faster (-16%)  |
| pickle_list             | 8.73 us      | 6.81 us: 1.28x faster (-22%)  |
| pickle_pure_python      | 1.03 ms      | 915 us: 1.13x faster (-11%)   |
| pidigits                | 277 ms       | 274 ms: 1.01x faster (-1%)    |
| python_startup          | 18.3 ms      | 17.1 ms: 1.07x faster (-7%)   |
| python_startup_no_site  | 10.0 ms      | 9.39 ms: 1.07x faster (-7%)   |
| raytrace                | 1.29 sec     | 1.13 sec: 1.14x faster (-12%) |
| regex_compile           | 319 ms       | 287 ms: 1.11x faster (-10%)   |
| regex_dna               | 268 ms       | 244 ms: 1.10x faster (-9%)    |
| regex_effbot            | 5.29 ms      | 5.10 ms: 1.04x faster (-3%)   |
| regex_v8                | 42.7 ms      | 39.9 ms: 1.07x faster (-7%)   |
| richards                | 169 ms       | 144 ms: 1.17x faster (-15%)   |
| scimark_fft             | 617 ms       | 591 ms: 1.04x faster (-4%)    |
| scimark_lu              | 500 ms       | 458 ms: 1.09x faster (-8%)    |
| scimark_monte_carlo     | 216 ms       | 202 ms: 1.07x faster (-6%)    |
| scimark_sor             | 487 ms       | 430 ms: 1.13x faster (-12%)   |
| scimark_sparse_mat_mult | 7.47 ms      | 7.30 ms: 1.02x faster (-2%)   |
| spectral_norm           | 289 ms       | 285 ms: 1.01x faster (-1%)    |
| sqlalchemy_declarative  | 308 ms       | 286 ms: 1.07x faster (-7%)    |
| sqlalchemy_imperative   | 65.4 ms      | 60.4 ms: 1.08x faster (-8%)   |
| sqlite_synth            | 6.15 us      | 5.95 us: 1.03x faster (-3%)   |
| sympy_expand            | 995 ms       | 904 ms: 1.10x faster (-9%)    |
| sympy_integrate         | 42.9 ms      | 39.0 ms: 1.10x faster (-9%)   |
| sympy_sum               | 211 ms       | 191 ms: 1.11x faster (-10%)   |
| sympy_str               | 429 ms       | 388 ms: 1.11x faster (-10%)   |
| telco                   | 14.1 ms      | 13.0 ms: 1.08x faster (-8%)   |
| tornado_http            | 415 ms       | 378 ms: 1.10x faster (-9%)    |
| unpack_sequence         | 106 ns       | 87.0 ns: 1.22x faster (-18%)  |
| unpickle                | 31.4 us      | 26.7 us: 1.18x faster (-15%)  |
| unpickle_list           | 9.46 us      | 7.85 us: 1.20x faster (-17%)  |
| unpickle_pure_python    | 783 us       | 701 us: 1.12x faster (-10%)   |
| xml_etree_parse         | 272 ms       | 256 ms: 1.06x faster (-6%)    |
| xml_etree_iterparse     | 424 ms       | 362 ms: 1.17x faster (-15%)   |
| xml_etree_generate      | 252 ms       | 231 ms: 1.09x faster (-8%)    |
| xml_etree_process       | 197 ms       | 180 ms: 1.09x faster (-9%)    |


### Related Discussion Threads

 * [Link Time Optimizations support for GCC and CLANG](https://bugs.python.org/issue25702)
 * [Discussion regarding default LTO/PGO builds for Docker Library Python Images](https://github.com/docker-library/python/issues/160)
 * [Alpine Linux (Python) build issue](https://github.com/alpinelinux/aports/pull/1775)

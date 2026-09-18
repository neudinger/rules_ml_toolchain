/* Copyright 2026 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
==============================================================================
*/

#include "vector_musa.h"

#include <musa_runtime.h>

__global__ void VectorAdd(const int *a, const int *b, int *c, int n) {
  int i = threadIdx.x;
  if (i < n) {
    c[i] += a[i] + b[i];
  }
}

int VectorGenerateAndSum(int size) {
  int *a = nullptr;
  int *b = nullptr;
  int *c = nullptr;

  musaMallocManaged(&a, sizeof(int) * size);
  musaMallocManaged(&b, sizeof(int) * size);
  musaMallocManaged(&c, sizeof(int) * size);

  for (int i = 0; i < size; ++i) {
    a[i] = i + 1;
    b[i] = i + 1;
    c[i] = 0;
  }

  VectorAdd<<<1, size>>>(a, b, c, size);
  musaDeviceSynchronize();

  int sum = 0;
  for (int i = 0; i < size; ++i) {
    sum += c[i];
  }

  musaFree(a);
  musaFree(b);
  musaFree(c);

  return sum;
}

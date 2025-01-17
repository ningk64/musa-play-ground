# MUSA Cuda Compatible

## 代码迁移工具musify安装
https://blog.mthreads.com/blog/musa/2024-05-28-%E4%BD%BF%E7%94%A8musify%E5%AF%B9%E4%BB%A3%E7%A0%81%E8%BF%9B%E8%A1%8C%E5%B9%B3%E5%8F%B0%E8%BF%81%E7%A7%BB/

## 如何将Cuda代码一键平移至Musa代码
```
    # 复制原cuda代码
    cp 00_vector_add_v1_ori.cu 00_vector_add_v1_cp.cu

    # 使用工具一键将cuda 代码转换成musa代码
    musify-text 00_vector_add_v1_cp.cu --inplace

    # 编译
    mcc 00_vector_add_v1_cp.cu -o vector_add_v2 -mtgpu -O2 -lmusart
    
    # 执行代码
    ./vector_add_v2
```
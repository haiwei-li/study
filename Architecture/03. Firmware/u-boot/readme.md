
Uboot启动流程分析——上: https://doc.embedfire.com/lubancat/build_and_deploy/zh/latest/building_image/boot_image_analyse/boot_image_analyse.html


common/spl/spl.c

```
printf("Trying to boot from %s\n", loader->name);
```

```
Trying to boot from MMC1
```


common/spl/spl_mmc.c

```
Trying to boot from MMC1
```

```
SPL_LOAD_IMAGE_METHOD("MMC1", 0, BOOT_DEVICE_MMC1, spl_mmc_load_image);
```

common/spl/spl_mmc.c

```

```
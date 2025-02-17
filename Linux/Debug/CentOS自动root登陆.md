在文件 `/etc/systemd/system/getty.target.wants/getty@tty1.service` 中, 将 Service 中

```
ExecStart=-/sbin/agetty --noclear %I $TERM
```

修改成

```
ExecStart=-/sbin/agetty --autologin root --noclear %I $TERM
```
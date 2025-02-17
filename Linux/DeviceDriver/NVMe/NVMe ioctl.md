
对于 Nvme SSD, 我们有的时候会用到 ioctl 系统调用, 该调用的流程是怎样的呢?

首先, 在注册 nvme 设备的时候(`nvme_probe`), 会注册 file operations

`/dev/nvme%d`

```cpp
static const struct file_operations nvme_dev_fops = {
    .owner          = THIS_MODULE,
    .open           = nvme_dev_open,
    .release        = nvme_dev_release,
    .unlocked_ioctl = nvme_dev_ioctl,
    .compat_ioctl   = compat_ptr_ioctl,
};
```

在 `nvme_dev_ioctl` 里, 存在 switch 语句, 列举 ioctl 的几种 cmd, 其中主要关注的是: `NVME_IOCTL_ADMIN_CMD` 和 `NVME_IO_CMD`.

```cpp
// drivers/nvme/host/ioctl.c
long nvme_dev_ioctl(struct file *file, unsigned int cmd,
                unsigned long arg)
{
    struct nvme_ctrl *ctrl = file->private_data;
    void __user *argp = (void __user *)arg;

    switch (cmd) {
    case NVME_IOCTL_ADMIN_CMD:
        return nvme_user_cmd(ctrl, NULL, argp);
    case NVME_IOCTL_ADMIN64_CMD:
        return nvme_user_cmd64(ctrl, NULL, argp);
    case NVME_IOCTL_IO_CMD:
        return nvme_dev_user_cmd(ctrl, argp);
    case NVME_IOCTL_RESET:
        dev_warn(ctrl->device, "resetting controller\n");
        return nvme_reset_ctrl_sync(ctrl);
    case NVME_IOCTL_SUBSYS_RESET:
        return nvme_reset_subsystem(ctrl);
    case NVME_IOCTL_RESCAN:
        nvme_queue_scan(ctrl);
        return 0;
    default:
        return -ENOTTY;
    }
}
```

对于 ssd 的读写命令, 显然是要走 `NVME_IOCTL_IO_CMD` 这一分支, 该分支的函数主要做的事情是填充了 `nvme_command c` 命令: 

```cpp
nvme_dev_user_cmd() -> nvme_user_cmd()

static int nvme_user_cmd(struct nvme_ctrl *ctrl, struct nvme_ns *ns,
		struct nvme_passthru_cmd __user *ucmd, unsigned int flags,
		fmode_t mode)
{
	struct nvme_passthru_cmd cmd;
	struct nvme_command c;
	unsigned timeout = 0;
	u64 result;
	int status;

	if (copy_from_user(&cmd, ucmd, sizeof(cmd)))
		return -EFAULT;
	if (cmd.flags)
		return -EINVAL;
	if (!nvme_validate_passthru_nsid(ctrl, ns, cmd.nsid))
		return -EINVAL;

	memset(&c, 0, sizeof(c));
	c.common.opcode = cmd.opcode;
	c.common.flags = cmd.flags;
	c.common.nsid = cpu_to_le32(cmd.nsid);
	c.common.cdw2[0] = cpu_to_le32(cmd.cdw2);
	c.common.cdw2[1] = cpu_to_le32(cmd.cdw3);
	c.common.cdw10 = cpu_to_le32(cmd.cdw10);
	c.common.cdw11 = cpu_to_le32(cmd.cdw11);
	c.common.cdw12 = cpu_to_le32(cmd.cdw12);
	c.common.cdw13 = cpu_to_le32(cmd.cdw13);
	c.common.cdw14 = cpu_to_le32(cmd.cdw14);
	c.common.cdw15 = cpu_to_le32(cmd.cdw15);

	if (!nvme_cmd_allowed(ns, &c, 0, mode))
		return -EACCES;

	if (cmd.timeout_ms)
		timeout = msecs_to_jiffies(cmd.timeout_ms);

	status = nvme_submit_user_cmd(ns ? ns->queue : ctrl->admin_q, &c,
			cmd.addr, cmd.data_len, nvme_to_user_ptr(cmd.metadata),
			cmd.metadata_len, 0, &result, timeout, 0);

	if (status >= 0) {
		if (put_user(result, &ucmd->result))
			return -EFAULT;
	}

	return status;
}

static int nvme_submit_user_cmd(struct request_queue *q,
		struct nvme_command *cmd, u64 ubuffer, unsigned bufflen,
		void __user *meta_buffer, unsigned meta_len, u32 meta_seed,
		u64 *result, unsigned timeout, unsigned int flags)
{
	struct nvme_ctrl *ctrl;
	struct request *req;
	void *meta = NULL;
	struct bio *bio;
	u32 effects;
	int ret;
    // 分配一个 request
	req = nvme_alloc_user_request(q, cmd, 0, 0);
	if (IS_ERR(req))
		return PTR_ERR(req);

	req->timeout = timeout;
	if (ubuffer && bufflen) {
		ret = nvme_map_user_request(req, ubuffer, bufflen, meta_buffer,
				meta_len, meta_seed, &meta, NULL, flags);
		if (ret)
			return ret;
	}

	bio = req->bio;
	ctrl = nvme_req(req)->ctrl;

	ret = nvme_execute_passthru_rq(req, &effects);

	if (result)
		*result = le64_to_cpu(nvme_req(req)->result.u64);
	if (meta)
		ret = nvme_finish_user_metadata(req, meta_buffer, meta,
						meta_len, ret);
	if (bio)
		blk_rq_unmap_user(bio);
	blk_mq_free_request(req);

	if (effects)
		nvme_passthru_end(ctrl, effects, cmd, ret);

	return ret;
}
```





nvme ioctl 解密: https://www.cnblogs.com/mmmmmmmelody/p/10500263.html
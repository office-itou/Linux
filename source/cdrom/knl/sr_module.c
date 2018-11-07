// ****************************************************************************
// SCSI cdrom (sr) device driver
// ****************************************************************************

// ::: debug ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define DEBUG

// ::: include ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#include "sr_module.h"					// SCSI cdrom (sr) device driver's header

// ::: global :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
static struct sr_unit sr;
static int sr_major = 0;

// ============================================================================
static DEFINE_MUTEX(sr_mutex);
static DEFINE_SPINLOCK(sr_lock);

// ::: struct cdrom_device_ops ::::::::::::::::::::::::::::::::::::::::::::::::
static int sr_open(struct cdrom_device_info *cdi, int purpose)
{
	int result = 0;

	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return result;
}

// ============================================================================
static void sr_release(struct cdrom_device_info *cdi)
{
	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
}

// ============================================================================
static int sr_drive_status(struct cdrom_device_info *cdi, int slot)
{
	int result = CDS_DISC_OK;
	const struct my_toc *toc = sr.toc;

	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	if (slot != CDSL_CURRENT)
		return -EINVAL;

	if (!toc->initial)
		return -ENOMEDIUM;

	return result;
}

// ============================================================================
static unsigned int sr_check_events(struct cdrom_device_info *cdi, unsigned int clearing, int slot)
{
	unsigned int result = 0;
	struct my_toc *toc = sr.toc;

	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	if (slot != CDSL_CURRENT)
		return -EINVAL;

	if (toc->mchange) {
		toc->mchange = 0;
		return DISK_EVENT_MEDIA_CHANGE;
	}

	return result;
}

// ============================================================================
static int sr_get_last_session(struct cdrom_device_info *cdi, struct cdrom_multisession *ms_info)
{
	int result = 0;
	const struct my_toc *toc = sr.toc;

	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	ms_info->addr_format = CDROM_LBA;
	ms_info->addr.lba = toc->leadout;
	ms_info->xa_flag = 1;

	return result;
}

// ============================================================================
static int sr_reset(struct cdrom_device_info *cdi)
{
	int result = 0;

	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return result;
}

// ============================================================================
#if LINUX_VERSION_CODE < KERNEL_VERSION(4, 11, 0)
static int sr_generic_packet(struct cdrom_device_info *cdi, struct packet_command *cgc)
{
	int result = 0;

	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	result = -EIO;
	cgc->stat = result;
	return result;
}
#endif

// ============================================================================
static struct cdrom_device_ops sr_ops = {
	.open = sr_open,
	.release = sr_release,
	.drive_status = sr_drive_status,
	.check_events = sr_check_events,
	.get_last_session = sr_get_last_session,
	.reset = sr_reset,
	.capability = SR_CAPABILITIES,
#if LINUX_VERSION_CODE < KERNEL_VERSION(4, 11, 0)
	.generic_packet = sr_generic_packet,
#else
	.generic_packet = cdrom_dummy_generic_packet,
#endif
};

// ::: struct block_device_operations :::::::::::::::::::::::::::::::::::::::::
static int sr_bdops_open(struct block_device *bdev, fmode_t mode)
{
	int result = 0;

	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	check_disk_change(bdev);
	mutex_lock(&sr_mutex);
	result = cdrom_open(sr.cdi, bdev, mode);
	mutex_unlock(&sr_mutex);
	return result;
}

// ============================================================================
static void sr_bdops_release(struct gendisk *disk, fmode_t mode)
{
	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	mutex_lock(&sr_mutex);
	cdrom_release(sr.cdi, mode);
	mutex_unlock(&sr_mutex);
}

// ============================================================================
static unsigned int sr_bdops_check_events(struct gendisk *disk, unsigned int clearing)
{
	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return cdrom_check_events(sr.cdi, clearing);
}

// ============================================================================
static int sr_bdops_ioctl(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	int result = 0;
	void __user *argp = (void __user *) arg;

	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	mutex_lock(&sr_mutex);
	switch (cmd) {
	default:
		result = cdrom_ioctl(sr.cdi, bdev, mode, cmd, arg);
		break;
	case SR_LOAD_MEDIA:
		result = sr_do_load_media(&sr, argp);
		break;
	case SG_IO:
		result = scsi_cmd_blk_ioctl(bdev, mode, cmd, argp);
		if (result != -ENOTTY)
			result = sr_do_gpcmd(&sr, argp);
		if (result == -ENOSYS)
			result = cdrom_ioctl(sr.cdi, bdev, mode, cmd, arg);
		break;
	}
	mutex_unlock(&sr_mutex);

	return result;
}

// ============================================================================
static const struct block_device_operations sr_bdops = {
	.owner = THIS_MODULE,
	.open = sr_bdops_open,
	.release = sr_bdops_release,
	.check_events = sr_bdops_check_events,
	.ioctl = sr_bdops_ioctl,
};

// ::: struct request_queue :::::::::::::::::::::::::::::::::::::::::::::::::::
static void sr_request(struct request_queue *rq)
{
	int result = 0;
	struct request *req;

	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	while ((req = blk_fetch_request(rq)) != NULL) {
		switch (req_op(req)) {
		case REQ_OP_READ:
			result = BLK_STS_OK;
			break;
		case REQ_OP_WRITE:
			pr_notice(SR_DEV_NAME ": Read only device - write request ignored\n");
			result = BLK_STS_IOERR;
			break;
		default:
			pr_devel(SR_DEV_NAME ": Non-fs request ignored\n");
			result = BLK_STS_IOERR;
			break;
		}
		__blk_end_request_all(req, BLK_STS_IOERR);
	}
}

// ::: struct platform_driver :::::::::::::::::::::::::::::::::::::::::::::::::
static void probe_sr_setupcd(void)
{
	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	sr.cdi->ops = &sr_ops;
	sr.cdi->capacity = 1;
	strncpy(sr.cdi->name, SR_DEV_NAME, sizeof(sr.cdi->name));
	sr.cdi->mask = CDC_CLOSE_TRAY | CDC_OPEN_TRAY | CDC_LOCK | CDC_SELECT_DISC;
}

// ============================================================================
static void probe_sr_setupdisk(void)
{
	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	sr.disk->major = sr_major;
	sr.disk->first_minor = 1;
	sr.disk->minors = 1;
	strncpy(sr.disk->disk_name, SR_DEV_NAME, sizeof(sr.disk->disk_name));
}

// ============================================================================
static void probe_sr_setupqueue(void)
{
	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	blk_queue_logical_block_size(sr.rq, SR_HARD_SECTOR);
	blk_queue_max_segments(sr.rq, 1);
	blk_queue_max_segment_size(sr.rq, 0x40000);
	sr.disk->queue = sr.rq;
}

// ============================================================================
static int probe_sr(struct platform_device *pdev)
{
	int result = 0;

	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	// --- register device ----------------------------------------------------
	sr_major = register_blkdev(0, SR_DEV_NAME);
	if (sr_major <= 0)
		return sr_major;
	pr_info(SR_DEV_NAME ": Registered with major number %d\n", sr_major);
	// --- memory allocation --------------------------------------------------
	sr.cdi = kzalloc(sizeof(struct cdrom_device_info), GFP_KERNEL);
	if (IS_ERR_OR_NULL(sr.cdi)) {
		result = PTR_ERR(sr.cdi);
		goto fail_1;
	}
	// --- memory allocation --------------------------------------------------
	sr.toc = kzalloc(sizeof(struct my_toc), GFP_KERNEL);
	if (IS_ERR_OR_NULL(sr.toc)) {
		result = PTR_ERR(sr.toc);
		goto fail_2;
	}
	// --- parameter setup ----------------------------------------------------
	probe_sr_setupcd();
	// ------------------------------------------------------------------------
	sr.disk = alloc_disk(1);
	if (IS_ERR_OR_NULL(sr.disk)) {
		result = PTR_ERR(sr.disk);
		goto fail_3;
	}
	// ------------------------------------------------------------------------
	probe_sr_setupdisk();
	// ------------------------------------------------------------------------
	result = register_cdrom(sr.cdi);
	if (result) {
		goto fail_4;
	}
	sr.disk->fops = &sr_bdops;
	// ------------------------------------------------------------------------
	sr.rq = blk_init_queue(sr_request, &sr_lock);
	if (IS_ERR_OR_NULL(sr.rq)) {
		result = PTR_ERR(sr.rq);
		goto fail_5;
	}
	blk_queue_bounce_limit(sr.rq, BLK_BOUNCE_HIGH);
	// ------------------------------------------------------------------------
	probe_sr_setupqueue();
	// ------------------------------------------------------------------------
	add_disk(sr.disk);
	// ------------------------------------------------------------------------
	return 0;
	// ------------------------------------------------------------------------
//  blk_cleanup_queue(sr.rq);
  fail_5:
	unregister_cdrom(sr.cdi);
  fail_4:
	del_gendisk(sr.disk);
  fail_3:
	kfree(sr.toc);
  fail_2:
	kfree(sr.cdi);
  fail_1:
	unregister_blkdev(sr_major, SR_DEV_NAME);
	return result;
}

// ============================================================================
static int remove_sr(struct platform_device *pdev)
{
	int result = 0;

	pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	blk_cleanup_queue(sr.rq);
	unregister_cdrom(sr.cdi);
	del_gendisk(sr.disk);
	kfree(sr.toc);
	kfree(sr.cdi);
	unregister_blkdev(sr_major, SR_DEV_NAME);
	return result;
}

// ============================================================================
static struct platform_driver sr_driver = {
	.probe = probe_sr,
	.remove = remove_sr,
	.driver = {
			   .name = SR_DEV_NAME,
			   },
};

static struct platform_device *pd;

// ::: init / exit ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
static int __init init_sr(void)
{
	int result;

	result = platform_driver_register(&sr_driver);
	if (result)
		return result;

	pd = platform_device_register_simple(SR_DEV_NAME, -1, NULL, 0);
	if (IS_ERR_OR_NULL(pd)) {
		platform_driver_unregister(&sr_driver);
		return PTR_ERR(pd);
	}

	pr_info(SR_DEV_NAME ": %s initialised\n", SR_DESCRIPTION);
	return result;
}

// ============================================================================
static void __exit exit_sr(void)
{
	platform_device_unregister(pd);
	platform_driver_unregister(&sr_driver);
	pr_info(SR_DEV_NAME ": %s releases\n", SR_DESCRIPTION);
}

// ============================================================================
module_init(init_sr);
module_exit(exit_sr);

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
MODULE_AUTHOR(SR_AUTHOR);
MODULE_DESCRIPTION(SR_DESCRIPTION);
MODULE_LICENSE("GPL");

// *** EOF ********************************************************************

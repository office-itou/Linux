// ****************************************************************************
// SCSI cdrom (sr) device driver
// ****************************************************************************

// ::: debug ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define NDEBUG

// ::: include ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#include "sr_device.h"					// SCSI cdrom (sr) device driver

// ::: global :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
static int sr_major = 0;
static int sr_minor = 0;
static char sr_device[32] = "";
static char *sr_name = DEVICE_NAME;
static struct scsi_cd *cd = NULL;
static struct platform_device *pd = NULL;

// === mutex ==================================================================
static DEFINE_MUTEX(sr_mutex);
static DEFINE_SPINLOCK(sr_lock);

// === struct block_device_operations =========================================
static int sr_block_open(struct block_device *bdev, fmode_t mode);
static void sr_block_release(struct gendisk *disk, fmode_t mode);
static int sr_block_ioctl(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg);
static unsigned int sr_block_check_events(struct gendisk *disk, unsigned int clearing);

// === struct cdrom_device_ops ================================================
static int sr_open(struct cdrom_device_info *cdi, int purpose);
static void sr_release(struct cdrom_device_info *cdi);
static int sr_drive_status(struct cdrom_device_info *cdi, int slot);
static unsigned int sr_check_events(struct cdrom_device_info *cdi, unsigned int clearing, int slot);
static int sr_reset(struct cdrom_device_info *cdi);
static int sr_get_last_session(struct cdrom_device_info *cdi, struct cdrom_multisession *ms_info);

// === do request =============================================================
static void sr_readdisk_dma(struct work_struct *work);
static DECLARE_WORK(work, sr_readdisk_dma);
static LIST_HEAD(sr_deferred);

static void sr_do_request(struct request_queue *q);

// === struct scsi_driver =====================================================
static int sr_probe(struct platform_device *dev);
static int sr_remove(struct platform_device *dev);

// === struct block_device_operations =========================================
static struct block_device_operations sr_bdops = {
	.owner = THIS_MODULE,
	.open = sr_block_open,
	.release = sr_block_release,
	.ioctl = sr_block_ioctl,
	.check_events = sr_block_check_events,
};

// === struct cdrom_device_ops ================================================
static struct cdrom_device_ops sr_dops = {
	.open = sr_open,
	.release = sr_release,
	.drive_status = sr_drive_status,
	.check_events = sr_check_events,
	.get_last_session = sr_get_last_session,
	.reset = sr_reset,
	.capability = SR_CAPABILITIES,
};

// === struct scsi_driver =====================================================
static struct platform_driver sr_driver = {
	.probe = sr_probe,
	.remove = sr_remove,
	.driver = {
			   .name = DEVICE_NAME,
			   },
};

// ::: struct block_device_operations :::::::::::::::::::::::::::::::::::::::::
static int sr_block_open(struct block_device *bdev, fmode_t mode)
{
	int result = 0;
	struct cdrom_device_info *cdi = &cd->cdi;

	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);

	check_disk_change(bdev);

	mutex_lock(&sr_mutex);
	result = cdrom_open(cdi, bdev, mode);
	mutex_unlock(&sr_mutex);

	return result;
}

// ============================================================================
static void sr_block_release(struct gendisk *disk, fmode_t mode)
{
	struct cdrom_device_info *cdi = &cd->cdi;

	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	mutex_lock(&sr_mutex);
	cdrom_release(cdi, mode);
	mutex_unlock(&sr_mutex);
}

// ============================================================================
static int sr_block_ioctl(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	int result = 0;
	struct cdrom_device_info *cdi = &cd->cdi;
	void __user *argp = (void __user *) arg;

	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	pr_devel(DEVICE_NAME ": enter %s: %04x: %s\n", __FUNCTION__, cmd, my_msg_ioctl_cmd(cmd));

	mutex_lock(&sr_mutex);
	switch (cmd) {
	default:
		result = cdrom_ioctl(cdi, bdev, mode, cmd, arg);
		break;
	case SR_LOAD_MEDIA:
		result = sr_do_load_media(cd, argp);
		break;
	case SG_IO:
		result = scsi_cmd_blk_ioctl(bdev, mode, cmd, argp);
		if (result != -ENOTTY)
			result = sr_do_gpcmd(cd, argp);
		if (result == -ENOSYS)
			result = cdrom_ioctl(cdi, bdev, mode, cmd, arg);
		break;
	}
	mutex_unlock(&sr_mutex);

	return result;
}

// ============================================================================
static unsigned int sr_block_check_events(struct gendisk *disk, unsigned int clearing)
{
	unsigned int result = 0;
	struct cdrom_device_info *cdi = &cd->cdi;

	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	result = cdrom_check_events(cdi, clearing);
	return result;
}

// ::: struct cdrom_device_ops ::::::::::::::::::::::::::::::::::::::::::::::::
static int sr_open(struct cdrom_device_info *cdi, int purpose)
{
	int result = 0;

	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	if (IS_ERR_OR_NULL(cd))
		return PTR_ERR(cd);

	cdi = &cd->cdi;
	return result;
}

// ============================================================================
static void sr_release(struct cdrom_device_info *cdi)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
}

// ============================================================================
static int sr_drive_status(struct cdrom_device_info *cdi, int slot)
{
	int result = CDS_DISC_OK;
	const struct my_toc *toc = &cd->toc;

	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);

	if (slot != CDSL_CURRENT)
		return -EINVAL;

	if (IS_ERR_OR_NULL(cd))
		return PTR_ERR(cd);

	if (!toc->initial)
		return -ENOMEDIUM;

	return result;
}

// ============================================================================
static unsigned int sr_check_events(struct cdrom_device_info *cdi, unsigned int clearing, int slot)
{
	unsigned int result = 0;
	struct my_toc *toc = &cd->toc;

	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);

	if (slot != CDSL_CURRENT)
		return -EINVAL;

	if (IS_ERR_OR_NULL(cd))
		return PTR_ERR(cd);

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

	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);

	if (IS_ERR_OR_NULL(cd))
		return PTR_ERR(cd);

	ms_info->addr_format = CDROM_LBA;
	ms_info->addr.lba = cd->toc.leadout;
	ms_info->xa_flag = 1;

	return result;
}

// ============================================================================
static int sr_reset(struct cdrom_device_info *cdi)
{
	int result = 0;

	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);

	if (IS_ERR_OR_NULL(cd))
		return PTR_ERR(cd);

	return result;
}

// ::: do request :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
static void sr_readdisk_dma(struct work_struct *work)
{
	struct list_head *elem, *next;
	struct request *req;

	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);

	if (list_empty(&sr_deferred))
		return;

	spin_lock(&sr_lock);
	list_for_each_safe(elem, next, &sr_deferred) {
		req = list_entry(elem, struct request, queuelist);
		list_del_init(&req->queuelist);
		__blk_end_request_all(req, 0);
	}
	spin_unlock(&sr_lock);
}

// ============================================================================
static void sr_do_request(struct request_queue *q)
{
	struct request *req;

	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);

	while ((req = blk_fetch_request(q)) != NULL) {
		switch (req_op(req)) {
		case REQ_OP_READ:
			list_add_tail(&req->queuelist, &sr_deferred);
			schedule_work(&work);
			break;
		case REQ_OP_WRITE:
			pr_notice(DEVICE_NAME ": Read only device - write request ignored\n");
			__blk_end_request_all(req, BLK_STS_IOERR);
			break;
		default:
			pr_devel(DEVICE_NAME ": Non-fs request ignored\n");
			__blk_end_request_all(req, BLK_STS_IOERR);
			break;
		}
	}
}

// ::: struct scsi_driver :::::::::::::::::::::::::::::::::::::::::::::::::::::
static void sr_probe_setuo_cd(struct scsi_cd *cd)
{
	struct cdrom_device_info *cdi = &cd->cdi;
	struct gendisk *disk = cd->disk;

	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	cdi->ops = &sr_dops;
	cdi->disk = disk;
	cdi->handle = cd;
	cdi->mask = 0;
	cdi->speed = 0;
	cdi->capacity = 1;
	strncpy(cdi->name, sr_device, sizeof(cdi->name));
}

// ============================================================================
static void sr_probe_setup_disk(struct scsi_cd *cd)
{
	struct gendisk *disk = cd->disk;

	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	disk->major = sr_major;
	disk->first_minor = sr_minor;
	disk->minors = 1;
	strncpy(disk->disk_name, sr_device, sizeof(disk->disk_name));
	disk->events = DISK_EVENT_MEDIA_CHANGE | DISK_EVENT_EJECT_REQUEST;
	disk->fops = &sr_bdops;
//  disk->queue cd->rq;
//  disk->private_data = cd;
	disk->flags = GENHD_FL_CD | GENHD_FL_BLOCK_EVENTS_ON_EXCL_WRITE;
}

// ============================================================================
static void sr_probe_setup_queue(struct scsi_cd *cd)
{
	struct gendisk *disk = cd->disk;

	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	blk_queue_logical_block_size(cd->rq, SR_HARD_SECTOR);
	blk_queue_max_segments(cd->rq, 1);
	blk_queue_max_segment_size(cd->rq, 0x40000);
	blk_queue_rq_timeout(cd->rq, SR_TIMEOUT);
	disk->private_data = cd;
	disk->queue = cd->rq;
}

// ============================================================================
static int sr_probe(struct platform_device *dev)
{
	int result = 0;

	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	// ------------------------------------------------------------------------
	result = register_blkdev(0, sr_name);
	if (result < 0)
		goto fail_1;
	sr_major = result;
	snprintf(sr_device, sizeof(sr_device), "%s%d", sr_name, sr_minor);
	// ------------------------------------------------------------------------
	cd = kzalloc(sizeof(struct scsi_cd), GFP_KERNEL);
	if (IS_ERR_OR_NULL(cd)) {
		result = PTR_ERR(cd);
		goto fail_2;
	}
	sr_probe_setuo_cd(cd);
	// ------------------------------------------------------------------------
	cd->disk = alloc_disk(1);
	if (IS_ERR_OR_NULL(cd->disk)) {
		result = PTR_ERR(cd->disk);
		goto fail_3;
	}
	sr_probe_setup_disk(cd);
	// ------------------------------------------------------------------------
	cd->rq = blk_init_queue(sr_do_request, &sr_lock);
	if (IS_ERR_OR_NULL(cd->rq)) {
		result = PTR_ERR(cd->rq);
		goto fail_4;
	}
	sr_probe_setup_queue(cd);
	// ------------------------------------------------------------------------
	result = register_cdrom(&cd->cdi);
	if (result < 0)
		goto fail_5;
	// ------------------------------------------------------------------------
	add_disk(cd->disk);
	// ------------------------------------------------------------------------
	pr_info(DEVICE_NAME ": Attached scsi CD-ROM %s\n", sr_device);
	pr_info(DEVICE_NAME ": Registered with major number %d\n", sr_major);
	return 0;
	// ------------------------------------------------------------------------
/*
	unregister_cdrom(&cd->cdi);
*/
  fail_5:
	blk_cleanup_queue(cd->rq);
  fail_4:
	del_gendisk(cd->disk);
	put_disk(cd->disk);
  fail_3:
	kfree(cd);
  fail_2:
	unregister_blkdev(sr_major, sr_name);
	sr_major = 0;
  fail_1:
	pr_warning("Probe failed - error is 0x%X\n", result);
	return result;
}

// ============================================================================
static int sr_remove(struct platform_device *dev)
{
	pr_devel(DEVICE_NAME ": enter %s\n", __FUNCTION__);
	flush_work(&work);
	unregister_cdrom(&cd->cdi);
	blk_cleanup_queue(cd->rq);
	del_gendisk(cd->disk);
	put_disk(cd->disk);
	kfree(cd);
	unregister_blkdev(sr_major, sr_name);
	sr_major = 0;
	return 0;
}

// ::: load / unload ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
static int probe_sr(void)
{
	int result = 0;

	result = platform_driver_register(&sr_driver);
	if (result)
		return result;

	pd = platform_device_register_simple(DEVICE_NAME, -1, NULL, 0);
	if (IS_ERR(pd)) {
		platform_driver_unregister(&sr_driver);
		return PTR_ERR(pd);
	}

	return 0;
}

// ============================================================================
static void remove_sr(void)
{
	platform_device_unregister(pd);
	platform_driver_unregister(&sr_driver);
}

// ============================================================================
static int __init init_sr(void)
{
	int result;

	result = probe_sr();
	if (!result)
		pr_info(DEVICE_NAME ": %s initialised\n", DESCRIPTION);
	return result;
}

// ============================================================================
static void __exit exit_sr(void)
{
	remove_sr();
	pr_info(DEVICE_NAME ": %s releases\n", DESCRIPTION);
}

// ============================================================================
module_init(init_sr);
module_exit(exit_sr);

// ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
MODULE_DESCRIPTION(DESCRIPTION);
MODULE_LICENSE("GPL");
MODULE_AUTHOR(AUTHOR);

// *** EOF ********************************************************************

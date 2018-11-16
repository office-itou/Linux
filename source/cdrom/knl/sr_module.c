// ****************************************************************************
// SCSI cdrom (sr) device driver
// ****************************************************************************

// ::: debug ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#define DEBUG

// ::: include ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#include "sr_module.h"					// SCSI cdrom (sr) device driver's header

// ::: global :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
MODULE_AUTHOR(SR_AUTHOR);
MODULE_DESCRIPTION(SR_DESCRIPTION);
MODULE_LICENSE("GPL");

// ============================================================================
static int sr_major = 0;
static int sr_minor = 0;
static struct my_toc *toc = NULL;
static struct scsi_cd *cd = NULL;

// ============================================================================
static DEFINE_MUTEX(sr_mutex);
static DEFINE_SPINLOCK(sr_lock);

// ::: struct block_device_operations :::::::::::::::::::::::::::::::::::::::::
static int sr_block_open(struct block_device *bdev, fmode_t mode)
{
	int result = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	check_disk_change(bdev);

	mutex_lock(&sr_mutex);
	result = cdrom_open(&cd->cdi, bdev, mode);
	mutex_unlock(&sr_mutex);

	return result;
}

// ============================================================================
static void sr_block_release(struct gendisk *disk, fmode_t mode)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	mutex_lock(&sr_mutex);
	cdrom_release(&cd->cdi, mode);
	mutex_unlock(&sr_mutex);
}

// ============================================================================
static unsigned int sr_block_check_events(struct gendisk *disk, unsigned int clearing)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	return cdrom_check_events(&cd->cdi, clearing);
}

// ============================================================================
static int sr_block_ioctl(struct block_device *bdev, fmode_t mode, unsigned cmd, unsigned long arg)
{
	int result = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	switch (cmd) {
	case SR_LOAD_MEDIA:
		result = sr_do_load_media(toc, arg);
		break;
	case SG_IO:
		result = sr_do_gpcmd(toc, cd, bdev, mode, cmd, arg);
		break;
	default:
		pr_devel(SR_DEV_NAME ": enter %s: %04x: %s\n", __FUNCTION__, cmd, my_msg_ioctl_cmd(cmd));
		mutex_lock(&sr_mutex);
		result = cdrom_ioctl(&cd->cdi, bdev, mode, cmd, arg);
		mutex_unlock(&sr_mutex);
		break;
	}

	return result;
}

// ============================================================================
static struct block_device_operations sr_bdops = {
	.owner = THIS_MODULE,
	.open = sr_block_open,
	.release = sr_block_release,
//  .rw_page = sr_rw_page,
	.ioctl = sr_block_ioctl,
//  .compat_ioctl = sr_compat_ioctl,
	.check_events = sr_block_check_events,
//  .media_changed = sr_media_changed,
//  .unlock_native_capacity = sr_unlock_native_capacity,
//  .revalidate_disk = sr_revalidate_disk,
//  .getgeo = sr_getgeo,
//  .swap_slot_free_notify = sr_swap_slot_free_notify,
//  .pr_ops = &sr_pr_ops,
};

// ::: struct cdrom_device_ops ::::::::::::::::::::::::::::::::::::::::::::::::
static int sr_open(struct cdrom_device_info *cdi, int purpose)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	return 0;
}

// ============================================================================
static void sr_release(struct cdrom_device_info *cdi)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
}

// ============================================================================
static int sr_drive_status(struct cdrom_device_info *cdi, int slot)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	if (!toc->initial || toc->mchange)
		return CDS_NO_DISC;

	return CDS_DISC_OK;
}

// ============================================================================
static unsigned int sr_check_events(struct cdrom_device_info *cdi, unsigned int clearing, int slot)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	if (!toc->initial || !toc->mchange)
		return 0;

	toc->mchange = 0;

	return DISK_EVENT_MEDIA_CHANGE;
}

// ============================================================================
static int sr_media_changed(struct cdrom_device_info *cdi, int queue)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_tray_move(struct cdrom_device_info *cdi, int pos)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_lock_door(struct cdrom_device_info *cdi, int lock)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_select_speed(struct cdrom_device_info *cdi, int speed)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_select_disc(struct cdrom_device_info *cdi, int slot)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_get_last_session(struct cdrom_device_info *cdi, struct cdrom_multisession *ms_info)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_get_mcn(struct cdrom_device_info *cdi, struct cdrom_mcn *mcn)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_reset(struct cdrom_device_info *cdi)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_audio_ioctl(struct cdrom_device_info *cdi, unsigned int cmd, void *arg)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static int sr_generic_packet(struct cdrom_device_info *cdi, struct packet_command *cgc)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return 0;
}

// ============================================================================
static struct cdrom_device_ops sr_dops = {
	.open = sr_open,
	.release = sr_release,
	.drive_status = sr_drive_status,
	.check_events = sr_check_events,
	.media_changed = sr_media_changed,
	.tray_move = sr_tray_move,
	.lock_door = sr_lock_door,
	.select_speed = sr_select_speed,
	.select_disc = sr_select_disc,
	.get_last_session = sr_get_last_session,
	.get_mcn = sr_get_mcn,
	.reset = sr_reset,
	.audio_ioctl = sr_audio_ioctl,
	.capability = SR_CAPABILITIES,
	.generic_packet = sr_generic_packet,
};

// ::: struct request_queue :::::::::::::::::::::::::::::::::::::::::::::::::::
static void sr_request(struct request_queue *rq)
{
	struct request *req;

	while ((req = blk_fetch_request(rq)) != NULL) {
		switch (req_op(req)) {
		case REQ_OP_READ:
			__blk_end_request_all(req, BLK_STS_OK);
			break;
		case REQ_OP_WRITE:
			pr_notice("Read only device - write request ignored\n");
			__blk_end_request_all(req, BLK_STS_IOERR);
			break;
		default:
			printk(KERN_DEBUG "gdrom: Non-fs request ignored\n");
			__blk_end_request_all(req, BLK_STS_IOERR);
			break;
		}
	}
}

// ::: probe / remove :::::::::::::::::::::::::::::::::::::::::::::::::::::::::
static void sr_probe_setupcd(struct device *dev, struct scsi_cd *cd)
{
	struct cdrom_device_info *cdi = &cd->cdi;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	cd->vendor = VENDOR_SCSI3;
	if (!strncmp(SR_VENDOR, "NEC", 3)) {
		cd->vendor = VENDOR_NEC;
	} else if (!strncmp(SR_VENDOR, "TOSHIBA", 7)) {
		cd->vendor = VENDOR_TOSHIBA;
	}
	cdi->handle = cd;
	cdi->ops = &sr_dops;
	cdi->mask = SR_MASK;
	cdi->capacity = 1;
	snprintf(cdi->name, sizeof(cdi->name), "%s%d", SR_DEV_NAME, sr_minor);
}

// ============================================================================
static void sr_probe_setupdisk(struct device *dev, struct scsi_cd *cd)
{
	struct cdrom_device_info *cdi = &cd->cdi;
	struct gendisk *disk = cd->disk;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	disk->fops = &sr_bdops;
	disk->major = sr_major;
	disk->first_minor = sr_minor;
	disk->minors = 1;
	sprintf(disk->disk_name, "%s%d", SR_DEV_NAME, sr_minor);
	disk->flags = 0;
	disk->events = 0;
	disk->flags |= GENHD_FL_CD;
	disk->flags |= GENHD_FL_BLOCK_EVENTS_ON_EXCL_WRITE;
	disk->flags |= GENHD_FL_REMOVABLE;
	disk->events |= DISK_EVENT_MEDIA_CHANGE;
	disk->events |= DISK_EVENT_EJECT_REQUEST;
	cdi->disk = disk;
}

// ============================================================================
static int sr_probe(struct device *dev)
{
	int result = 0;

//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	toc = kzalloc(sizeof(*toc), GFP_KERNEL);
	if (IS_ERR_OR_NULL(toc)) {
		result = PTR_ERR(toc);
		goto fail_toc;
	}

	cd = kzalloc(sizeof(*cd), GFP_KERNEL);
	if (IS_ERR_OR_NULL(cd)) {
		result = PTR_ERR(cd);
		goto fail_cd;
	}
	sr_probe_setupcd(dev, cd);

	cd->disk = alloc_disk(1);
	if (IS_ERR_OR_NULL(cd->disk)) {
		result = PTR_ERR(cd->disk);
		goto fail_disk;
	}
	sr_probe_setupdisk(dev, cd);

	if (register_cdrom(&cd->cdi)) {
		result = -ENOMEM;
		goto fail_cdrom;
	}

	cd->disk->queue = blk_init_queue(sr_request, &sr_lock);
	if (IS_ERR_OR_NULL(cd->disk->queue)) {
		result = PTR_ERR(cd->disk->queue);
		goto fail_rq;
	}
	dev_set_drvdata(dev, cd);
	cd->disk->flags |= GENHD_FL_REMOVABLE;
	add_disk(cd->disk);

	pr_info(SR_DEV_NAME ": Attached scsi CD-ROM %s\n", cd->cdi.name);

	return 0;

  fail_rq:
	unregister_cdrom(&cd->cdi);
  fail_cdrom:
	put_disk(cd->disk);
  fail_disk:
	kfree(cd);
  fail_cd:
	kfree(toc);
  fail_toc:
	return result;
}

// ============================================================================
static int sr_remove(struct device *dev)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);

	del_gendisk(cd->disk);
	dev_set_drvdata(dev, NULL);
	unregister_cdrom(&cd->cdi);
	put_disk(cd->disk);
	blk_cleanup_queue(cd->disk->queue);
	kfree(cd);
	kfree(toc);

	return 0;
}

// ::: struct platform_driver :::::::::::::::::::::::::::::::::::::::::::::::::
static int probe_sr(struct platform_device *pdev)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return sr_probe(&pdev->dev);
}

// ============================================================================
static int remove_sr(struct platform_device *pdev)
{
//  pr_devel(SR_DEV_NAME ": enter %s\n", __FUNCTION__);
	return sr_remove(&pdev->dev);
}

// ============================================================================
static struct platform_driver sr_pdriver = {
	.probe = probe_sr,
	.remove = remove_sr,
	.driver = {
			   .name = SR_DEV_NAME,
			   },
};

static struct platform_device *pd = NULL;

// ::: init / exit ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
static int __init init_sr(void)
{
	int result = 0;

	sr_major = register_blkdev(0, SR_DEV_NAME);
	if (sr_major <= 0)
		return sr_major;
	pr_info(SR_DEV_NAME ": Registered with major number %d\n", sr_major);

	result = platform_driver_register(&sr_pdriver);
	if (result)
		goto fail_pdrv;

	pd = platform_device_register_simple(SR_DEV_NAME, -1, NULL, 0);
	if (IS_ERR(pd)) {
		result = PTR_ERR(pd);
		goto fail_pdev;
	}

	pr_info(SR_DEV_NAME ": %s initialised\n", SR_DESCRIPTION);

	return 0;

  fail_pdev:
	platform_driver_unregister(&sr_pdriver);
  fail_pdrv:
	unregister_blkdev(sr_major, SR_DEV_NAME);
	return result;
}

// ============================================================================
static void __exit exit_sr(void)
{
	platform_device_unregister(pd);
	platform_driver_unregister(&sr_pdriver);
	unregister_blkdev(sr_major, SR_DEV_NAME);

	pr_info(SR_DEV_NAME ": %s releases\n", SR_DESCRIPTION);
}

// ============================================================================
module_init(init_sr);
module_exit(exit_sr);

// *** EOF ********************************************************************

/* Block device Ram Disk driver */
#include <linux/module.h>
#include <linux/blkdev.h>

#define BRD_SECTOR_SIZE  512
#define BRD_FIRST_MINOR    0
#define BRD_MINOR_CNT     16
#define BRD_DEVICE_SIZE 2048			/* sectors */

static u_int brd_major = 0;
static u8 *dev_data;					/* Array where the disk stores its data */
static struct brd_device {
	unsigned int size;					/* Size is the size of the device (in sectors) */
	spinlock_t lock;					/* For exclusive access to our request queue */
	struct request_queue *brd_queue;	/* Our request queue */
	struct gendisk *brd_disk;			/* This is kernel's representation of an individual disk device */
} brd_dev;

static void ramdevice_write(sector_t sector_off, u8 * buffer, unsigned int sectors)
{
	memcpy(dev_data + sector_off * BRD_SECTOR_SIZE, buffer, sectors * BRD_SECTOR_SIZE);
}

static void ramdevice_read(sector_t sector_off, u8 * buffer, unsigned int sectors)
{
	memcpy(buffer, dev_data + sector_off * BRD_SECTOR_SIZE, sectors * BRD_SECTOR_SIZE);
}

static int brd_open(struct block_device *bdev, fmode_t mode)
{
	unsigned unit = iminor(bdev->bd_inode);
	if (unit > BRD_MINOR_CNT)
		return -ENODEV;

	return 0;
}

static void brd_close(struct gendisk *disk, fmode_t mode)
{
}

static int brd_transfer(struct request *req)
{
	int ret = 0;
	int dir = rq_data_dir(req);
	sector_t start_sector = blk_rq_pos(req);
	unsigned int sector_cnt = blk_rq_sectors(req);

	struct bio_vec bv;
	struct req_iterator iter;

	sector_t sector_offset = 0;
	unsigned int sectors;
	u8 *buffer;

	rq_for_each_segment(bv, req, iter) {
		if (bv.bv_len % BRD_SECTOR_SIZE != 0) {
			printk(KERN_ERR "brd: Should never happen: "
				   "bio size (%d) is not a multiple of BRD_SECTOR_SIZE (%d).\n"
				   "This may lead to data truncation.\n",
				   bv.bv_len, BRD_SECTOR_SIZE);
			ret = -EIO;
		}

		buffer = page_address(bv.bv_page) + bv.bv_offset;
		sectors = bv.bv_len / BRD_SECTOR_SIZE;

		if (dir == WRITE) {		/* Write to the device */
			ramdevice_write(start_sector + sector_offset, buffer, sectors);
		} else {				/* Read from the device */
			ramdevice_read(start_sector + sector_offset, buffer, sectors);
		}

		sector_offset += sectors;
	}

	if (sector_offset != sector_cnt) {
		printk(KERN_ERR
			   "brd: bio info doesn't match with the request info");
		ret = -EIO;
	}

	return ret;
}

static void brd_request(struct request_queue *q)
{
	struct request *req;
	int ret;

	while ((req = blk_fetch_request(q)) != NULL) {
		ret = brd_transfer(req);
		__blk_end_request_all(req, ret);
	}
}

static struct block_device_operations brd_fops = {
	.owner   = THIS_MODULE,
	.open    = brd_open,
	.release = brd_close,
};

static int __init brd_init(void)
{
	if ((dev_data = kzalloc(BRD_DEVICE_SIZE * BRD_SECTOR_SIZE, GFP_KERNEL)) == NULL) {
		printk(KERN_ERR "brd: kzalloc failure\n");
		return -ENOMEM;
	}

	brd_dev.size = BRD_DEVICE_SIZE;

	if ((brd_major = register_blkdev(brd_major, "brd")) <= 0) {
		printk(KERN_ERR "brd: Unable to get Major Number\n");
		kfree(dev_data);
		return -EBUSY;
	}

	spin_lock_init(&brd_dev.lock);

	if ((brd_dev.brd_queue = blk_init_queue(brd_request, &brd_dev.lock)) == NULL) {
		printk(KERN_ERR "brd: blk_init_queue failure\n");
		unregister_blkdev(brd_major, "brd");
		kfree(dev_data);
		return -ENOMEM;
	}

	if (!(brd_dev.brd_disk = alloc_disk(BRD_MINOR_CNT))) {
		printk(KERN_ERR "brd: alloc_disk failure\n");
		blk_cleanup_queue(brd_dev.brd_queue);
		unregister_blkdev(brd_major, "brd");
		kfree(dev_data);
		return -ENOMEM;
	}

	brd_dev.brd_disk->major = brd_major;					/* Setting the major number */
	brd_dev.brd_disk->first_minor = BRD_FIRST_MINOR;		/* Setting the first mior number */
	brd_dev.brd_disk->fops = &brd_fops;						/* Initializing the device operations */
	brd_dev.brd_disk->private_data = &brd_dev;				/* Driver-specific own internal data */
	brd_dev.brd_disk->queue = brd_dev.brd_queue;
	snprintf(brd_dev.brd_disk->disk_name, sizeof(brd_dev.brd_disk->disk_name), "brd");
	set_capacity(brd_dev.brd_disk, brd_dev.size);			/* Setting the capacity of the device in its gendisk structure */
	add_disk(brd_dev.brd_disk);								/* Adding the disk to the system */

	printk(KERN_INFO
		   "brd: Block device Ram Disk driver initialised (%d sectors; %d bytes)\n",
		   brd_dev.size, brd_dev.size * BRD_SECTOR_SIZE);

	return 0;
}

static void __exit brd_cleanup(void)
{
	del_gendisk(brd_dev.brd_disk);
	put_disk(brd_dev.brd_disk);
	blk_cleanup_queue(brd_dev.brd_queue);
	unregister_blkdev(brd_major, "brd");
	kfree(dev_data);

	printk(KERN_INFO
		   "brd: Block device Ram Disk driver releases\n");
}

module_init(brd_init);
module_exit(brd_cleanup);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Block device Ram Disk Driver");
MODULE_ALIAS_BLOCKDEV_MAJOR(brd_major);

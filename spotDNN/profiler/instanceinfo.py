import numpy as np
# Part 1 - get from AWS websites
instance_type=['p2.xlarge','g4dn.4xlarge','g3.8xlarge','g3.16xlarge','p2.8xlarge']
instance_gpus=[1,1,2,4,8]
instance_quota = np.array([2, 5, 5, 8, 5])
instance_spot_price = np.array([0.918, 0.3612, 0.6840, 1.5676, 2.1600])
bps = 1200

# Part 2 - profile using profiler
instance_speed = np.array([1885, 750, 1018, 1995, 2115])
instance_batch = np.array([1024, 1024, 1024, 1024, 1024])
instance_time = instance_batch * instance_gpus / instance_speed

param = 11.5
instance_bandwith = 142
instance_comp = instance_time - (2 * param/instance_bandwith - 2 * np.array(instance_gpus) * param/ 10000)

a = 0.8
b = 1.92

r1 = 876.5
r2 = -0.2
r3 = 2507.6
r4 = 0.5
# 3D SLAM using an iPhone camera

This project is a 3D SLAM implementation using an iPhone camera. The iPhone app in the lidar 
directory captures pointclouds and uploads them to server.py. The server then saves the pointclouds
to a postgres db.

view_controller.py starts a thread that gets the pointclouds from the db and runs the 3D SLAM algorithm
ICP on them. The result is a 3D map of the environment which is displayed in an Open3D visualizer.

Currently this is a work in progress and would be very hard for anyone but me to run.

## The database
The database is a local postgres database with 1 table called point_cloud. The table has 4 columns,
scan_id, x, y, z. The scan_id is a unique identifier for each scan and the x, y columns are the pixel
coordinates of the depth map. The z column is the depth in meters. There is also a sequence called
scan_id_seq which is used to generate the next scan_id.

## The iPhone app
The iPhone app is in the lidar directory, its written in Swift and uses the ARKit library to capture pointclouds. The app uploads
each scan to the servers local ip address. It sends a scan every .1 seconds. 

## Writeup
The writeup for this project is in misc/out/conference_101719.pdf

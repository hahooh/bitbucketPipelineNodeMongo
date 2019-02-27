# This is a dockerfile for bitbucket pipeline.
starts mongodb by "mongod &" if you want to start before tests

# base image
node:8.15.0-strtech

# mongo db version
mongo:3.6

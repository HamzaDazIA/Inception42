#!/bin/bash

set -e
echo "configuring Redis ..."

sed -i "s|bind 127.0.0.1 -::1|bind 0.0.0.0|g" /etc/redis/redis.conf
sed -i "s|# maxmemory <bytes>|maxmemory 50mb|g" /etc/redis/redis.conf
sed -i "s|# maxmemory-policy noeviction|maxmemory-policy allkeys-lru|g" /etc/redis/redis.conf
sed -i "s|protected-mode yes|protected-mode no|g" /etc/redis/redis.conf
sed -i "s|daemonize yes|daemonize no|g" /etc/redis/redis.conf

echo "Starting Redis server..."
exec redis-server /etc/redis/redis.conf
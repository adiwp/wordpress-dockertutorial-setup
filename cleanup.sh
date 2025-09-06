#!/bin/bash

# cleanup.sh - Menghentikan dan menghapus semua data, container, network, dan volume.

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}PERINGATAN: Skrip ini akan menghapus SEMUA DATA (database, file upload) secara permanen.${NC}"

read -p "Apakah Anda yakin ingin melanjutkan? [y/N] " -n 1 -r
echo
if [[ ! \$REPLY =~ ^[Yy]$ ]]
then
    echo "Proses dibatalkan."
    exit 1
fi

echo -e "\n- Menghentikan container dan menghapus volume..."
docker compose down -v

echo "- Menghapus file dan direktori yang dibuat..."
rm -f docker-compose.yml
rm -rf nginx

echo -e "\n${YELLOW}🧹 Pembersihan selesai.${NC}"

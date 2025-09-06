#!/bin/bash

# setup.sh - Skrip final untuk setup WordPress, Nginx, dan MySQL di Docker

# --- Warna untuk output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Memulai proses setup WordPress dengan Docker...${NC}"

# --- Langkah 1: Meminta Password dengan Aman ---
echo "Anda akan diminta untuk membuat password database."
while true; do
    read -sp "Masukkan password untuk root MySQL: " ROOT_PASSWORD
    echo
    read -sp "Masukkan password untuk user WordPress (wordpress_user): " USER_PASSWORD
    echo
    read -sp "Konfirmasi password user WordPress: " USER_PASSWORD_CONFIRM
    echo
    [ "$USER_PASSWORD" = "$USER_PASSWORD_CONFIRM" ] && break
    echo -e "${YELLOW}Password tidak cocok. Silakan coba lagi.${NC}"
done

# --- Langkah 2: Membuat struktur direktori ---
echo -e "\n- Membuat direktori 'nginx'..."
mkdir -p nginx

# --- Langkah 3: Membuat file docker-compose.yml dengan placeholder ---
echo "- Membuat file 'docker-compose.yml'..."
cat << EOF > docker-compose.yml
# File Konfigurasi Docker Compose untuk WordPress
# Menggunakan Nginx, PHP-FPM, dan MySQL dengan Healthcheck

services:
  # Service untuk Database MySQL
  db:
    image: mysql:latest
    container_name: wordpress_db
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: __ROOT_PASSWORD__
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress_user
      MYSQL_PASSWORD: __USER_PASSWORD__
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
    networks:
      - wordpress_net

  # Service untuk WordPress (PHP-FPM)
  # Menggunakan image fpm-alpine karena ringan dan sesuai untuk Nginx
  wordpress:
    image: wordpress:fpm-alpine
    container_name: wordpress_app
    depends_on:
      db:
        condition: service_healthy # Menunggu database benar-benar siap
    volumes:
      - wp_data:/var/www/html
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: wordpress_user
      WORDPRESS_DB_PASSWORD: __USER_PASSWORD__
    networks:
      - wordpress_net

  # Service untuk Web Server Nginx
  nginx:
    image: nginx:latest
    container_name: wordpress_nginx
    ports:
      - "8080:80"
    volumes:
      - wp_data:/var/www/html
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    restart: always
    depends_on:
      - wordpress
    networks:
      - wordpress_net

# Definisi Volumes
volumes:
  db_data: {}
  wp_data: {}

# Definisi Network
networks:
  wordpress_net:
    driver: bridge
EOF

# --- Langkah 4: Mengganti placeholder password di docker-compose.yml ---
# Menggunakan sed untuk keamanan agar karakter spesial di password tidak error
echo "- Mengkonfigurasi password..."
sed -i.bak "s/__ROOT_PASSWORD__/${ROOT_PASSWORD}/g" docker-compose.yml
sed -i.bak "s/__USER_PASSWORD__/${USER_PASSWORD}/g" docker-compose.yml
rm docker-compose.yml.bak # Hapus file backup yang dibuat sed di macOS

# --- Langkah 5: Membuat file konfigurasi Nginx ---
echo "- Membuat file 'nginx/default.conf'..."
cat << 'EOF' > nginx/default.conf
server {
    listen 80;
    server_name localhost;

    root /var/www/html;
    index index.php;

    client_max_body_size 64M;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass wordpress:9000; # 'wordpress' adalah nama service wordpress
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# --- Langkah 6: Menjalankan Docker Compose ---
echo -e "\n- Menjalankan semua service... (Proses ini mungkin jeda sejenak untuk menunggu database siap)"
docker compose up -d

echo -e "\n${GREEN}✅ Setup Selesai!${NC}"
echo -e "WordPress Anda sekarang siap diakses di: ${YELLOW}http://localhost:8080${NC}"
echo -e "Untuk menghentikan dan menghapus semuanya, jalankan script ${YELLOW}./cleanup.sh${NC}"

# =====================================================================
# STAGE 1: Pinjam Builder Resmi Milik Piper untuk Membuat Modul Python
# =====================================================================
FROM python:3.12 AS piper-builder

RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
    build-essential cmake ninja-build git

WORKDIR /app

# Download source code piper v1.4.2 langsung dari repositori git mereka
RUN git clone --depth 1 --branch v1.4.2 https://github.com/OHF-Voice/piper1-gpl.git .
RUN script/setup --dev
RUN script/dev_build
RUN script/package

# =====================================================================
# STAGE 2: Final Runtime Container (Menggunakan Python 3.12 + Node.js)
# =====================================================================
FROM python:3.12-slim
WORKDIR /app

# Bypass proteksi pip global di Python 3.12
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV DEBIAN_FRONTEND=noninteractive

# Install Node.js runtime, Supervisor, dan libgomp1 (wajib untuk biner AI C++)
RUN apt-get update && apt-get install -y \
    supervisor \
    curl \
    libgomp1 \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# 3. AMBIL HASIL BUILD PIPER DAN INSTALL SECARA LOKAL
COPY --from=piper-builder /app/dist/piper_tts-*linux*.whl ./dist/
RUN pip3 install ./dist/piper_tts-*linux*.whl && rm -rf ./dist

# =====================================================================
# 4. Jejalkan Seluruh Ekosistem Aplikasi Face-Sync Kamu
# =====================================================================
# Copy file env bawaan backend
COPY .env .
COPY ./bin/version.json .

# Copy model AI bawaan proyek ke folder kontainer
COPY ./bin/models ./models

# Copy biner Go utama, updater, dan worker C++ mentah dari komputer hos
COPY ./bin/backend .
COPY ./bin/updater .
COPY ./bin/main.bin .
RUN chmod +x backend updater main.bin

# Copy folder standalone hasil build Next.js WebUI
COPY ./bin/webui ./webui

# Copy konfigurasi Supervisor & skrip entrypoint kita
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Ekspos Port API Go (8000) dan Next.js (3000)
EXPOSE 8000 3000

ENTRYPOINT ["./entrypoint.sh"]
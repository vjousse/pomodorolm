FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    libwebkit2gtk-4.1-dev \
    libappindicator3-dev \
    librsvg2-dev \
    patchelf \
    libasound2-dev \
    nodejs \
    npm

RUN curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh

ADD . /app
WORKDIR /app
RUN npm i
RUN npm run tauri build

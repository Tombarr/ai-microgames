FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG GODOT_VERSION="4.5-stable"

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    python3 \
    python3-pip \
    libfontconfig1 \
    libxcursor1 \
    libxinerama1 \
    libxrandr2 \
    libxrender1 \
    libxi6 \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Download and install Godot (Auto-detect arch)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then GODOT_ARCH="arm64"; else GODOT_ARCH="x86_64"; fi && \
    echo "Detected architecture: $ARCH, using Godot arch: $GODOT_ARCH" && \
    wget -q https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.${GODOT_ARCH}.zip && \
    unzip -q Godot_v${GODOT_VERSION}_linux.${GODOT_ARCH}.zip && \
    mv Godot_v${GODOT_VERSION}_linux.${GODOT_ARCH} /usr/local/bin/godot && \
    chmod +x /usr/local/bin/godot && \
    rm Godot_v${GODOT_VERSION}_linux.${GODOT_ARCH}.zip

# Download and install Export Templates
RUN mkdir -p /opt/godot/templates \
    && wget -q https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz \
    && unzip -q Godot_v${GODOT_VERSION}_export_templates.tpz -d /opt/godot/templates \
    && rm Godot_v${GODOT_VERSION}_export_templates.tpz \
    && mv /opt/godot/templates/templates /opt/godot/templates/${GODOT_VERSION}

# Prepare a script to link templates for the user
RUN echo '#!/bin/bash\n\
mkdir -p $HOME/.local/share/godot/export_templates\n\
ln -sf /opt/godot/templates/'"${GODOT_VERSION}"' $HOME/.local/share/godot/export_templates/'"${GODOT_VERSION}"'\n\
echo "Export templates linked."' > /usr/local/bin/setup-godot-templates \
    && chmod +x /usr/local/bin/setup-godot-templates

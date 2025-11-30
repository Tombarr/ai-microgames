FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG GODOT_VERSION="4.5-stable"

# Install dependencies
# libfontconfig1 etc are needed for Godot to run (even headless often requires some libs)
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

# Download and install Godot
RUN wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip \
    && unzip Godot_v${GODOT_VERSION}_linux.x86_64.zip \
    && mv Godot_v${GODOT_VERSION}_linux.x86_64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm Godot_v${GODOT_VERSION}_linux.x86_64.zip

# Download and install Export Templates
RUN mkdir -p /opt/godot/templates \
    && wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz \
    && unzip Godot_v${GODOT_VERSION}_export_templates.tpz -d /opt/godot/templates \
    && rm Godot_v${GODOT_VERSION}_export_templates.tpz \
    # The unzip creates a 'templates' folder. We rename it to the specific version Godot expects.
    # Godot expects version like '4.5.stable'
    && mv /opt/godot/templates/templates /opt/godot/templates/4.5.stable

# Prepare a script to link templates for the user
RUN echo '#!/bin/bash\n\
mkdir -p $HOME/.local/share/godot/export_templates\n\
ln -sf /opt/godot/templates/4.5.stable $HOME/.local/share/godot/export_templates/4.5.stable\n\
echo "Export templates linked."' > /usr/local/bin/setup-godot-templates \
    && chmod +x /usr/local/bin/setup-godot-templates

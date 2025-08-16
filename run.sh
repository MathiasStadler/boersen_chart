#!/bin/bash

# Projekt bauen und ausführen
set -e

echo "🔍 Überprüfe Systemvoraussetzungen..."
if ! command -v cargo &> /dev/null; then
    echo "Rust ist nicht installiert. Installiere jetzt..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi

echo "🛠️ Baue Projekt im Release-Modus..."
cargo build --release

echo "🧪 Führe Unit-Tests aus..."
cargo test -- --test-threads=1 --nocapture

echo "📊 Führe Integrationstests aus..."
cargo test --tests -- --nocapture

echo "🚀 Starte Anwendung..."
cargo run --release

echo "✅ Alles erledigt! Das Fenster sollte sich jetzt öffnen."

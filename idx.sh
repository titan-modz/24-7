#!/bin/bash

# =====================================================
# Google IDX 24/7 Keep-Alive Auto Installer (Final Version)
# =====================================================
# This script:
# 1. Creates keep-alive.sh on port 9090
# 2. Makes it executable
# 3. Runs it in background
# 4. Adds it to auto-start on every reboot
# =====================================================

# === Configuration ===
PORT=9090
INTERVAL=120
SCRIPT_PATH="$HOME/keep-alive.sh"

echo "🟩 Installing Google IDX 24/7 Keep-Alive..."

# === Create keep-alive.sh ===
cat <<EOF > $SCRIPT_PATH
#!/bin/bash

# 24/7 Keep-Alive Script for Google IDX
# Keeps your workspace alive even when the browser is closed.

PORT=$PORT
INTERVAL=$INTERVAL

# Install dependencies
sudo apt update -y >/dev/null 2>&1
sudo apt install -y curl python3 -qq >/dev/null 2>&1

# Start simple web server
nohup python3 -m http.server \$PORT >/dev/null 2>&1 &

echo "🚀 Keep-alive server started on port \$PORT"
echo "💡 Pinging every \$INTERVAL seconds to prevent IDX idle timeout."

# Infinite loop to keep workspace alive
while true; do
  curl -s http://localhost:\$PORT >/dev/null 2>&1
  echo "💓 Workspace still alive at \$(date)"
  sleep \$INTERVAL
done
EOF

# === Make executable ===
chmod +x $SCRIPT_PATH

# === Add to auto-start on workspace restart ===
if ! grep -q "keep-alive.sh" ~/.bashrc; then
  echo "nohup $SCRIPT_PATH >/dev/null 2>&1 &" >> ~/.bashrc
fi

# === Start immediately ===
nohup $SCRIPT_PATH >/dev/null 2>&1 &

clear
echo "✅ Keep-Alive Installed Successfully!"
echo "-------------------------------------------"
echo "📂 Script: $SCRIPT_PATH"
echo "🌐 Port: $PORT"
echo "🔁 Auto-ping every $INTERVAL seconds"
echo "⚙️  Auto-start enabled on workspace reboot"
echo "🚀 Running now in background"
echo "-------------------------------------------"
echo ""
echo "👉 If you saved this as install-keepalive.sh, run these commands:"
echo "chmod +x install-keepalive.sh"
echo "./install-keepalive.sh"
echo ""
echo "💡 To view logs, run: tail -f ~/keep-alive.log"

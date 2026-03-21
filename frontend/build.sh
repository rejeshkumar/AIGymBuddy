#!/bin/bash
set -e
# Install Flutter if not present
if [ ! -d ".flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable .flutter
fi
.flutter/bin/flutter config --enable-web
.flutter/bin/flutter pub get
.flutter/bin/flutter build web --release --dart-define=API_BASE_URL=https://aigymbuddy.onrender.com

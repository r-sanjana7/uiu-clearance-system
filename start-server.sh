#!/bin/bash
# Starts the PHP dev server on port 8000 from the project root.
# Open http://localhost:8000 in a browser after running this.
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"
echo "Serving UIU Clearance at http://localhost:8000"
echo "Press Ctrl+C to stop."
exec php -S localhost:8000

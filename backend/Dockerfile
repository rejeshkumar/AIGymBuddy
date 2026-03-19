FROM python:3.11-slim

WORKDIR /app

# Install system deps for tesseract (OCR) and pymupdf
RUN apt-get update && apt-get install -y --no-install-recommends \
    tesseract-ocr \
    libmupdf-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Run migrations and start server
CMD python init_db.py 2>/dev/null || true && \
    uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}

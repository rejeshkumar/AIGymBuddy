from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from typing import Optional
import re
import io

from models import User
from schemas import HealthReportResponse
from auth import get_current_user

router = APIRouter()

# Try to import OCR (optional - install pytesseract + pillow)
try:
    import pytesseract
    from PIL import Image
    OCR_AVAILABLE = True
except ImportError:
    OCR_AVAILABLE = False

# Try to import PDF support (optional - install pymupdf)
try:
    import fitz  # PyMuPDF
    PDF_AVAILABLE = True
except ImportError:
    PDF_AVAILABLE = False


def _pdf_to_images(pdf_bytes: bytes) -> list:
    """Convert PDF pages to PIL Images for OCR."""
    if not PDF_AVAILABLE:
        return []
    images = []
    try:
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
    except Exception as e:
        raise ValueError(f"Invalid or corrupted PDF: {e}") from e
    try:
        for page_num in range(len(doc)):
            page = doc.load_page(page_num)
            pix = page.get_pixmap(dpi=150, alpha=False)
            try:
                # Convert to RGB if needed (e.g. CMYK PDFs)
                if pix.n != 3:
                    pix = fitz.Pixmap(fitz.csRGB, pix)
                # Use PNG bytes for robust PIL loading
                png_bytes = pix.tobytes("png")
                img = Image.open(io.BytesIO(png_bytes)).convert("RGB")
            except Exception:
                # Fallback: direct RGB from samples
                img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
            images.append(img)
    finally:
        doc.close()
    return images


def parse_health_values(text: str) -> dict:
    """Extract common health metrics from OCR text."""
    result = {}
    text_lower = text.lower()

    # HbA1c
    hba1c_match = re.search(r"hba1c[:\s]*(\d+\.?\d*)", text_lower, re.IGNORECASE)
    if hba1c_match:
        result["hba1c"] = float(hba1c_match.group(1))

    # Cholesterol
    chol_match = re.search(r"cholesterol[:\s]*(\d+\.?\d*)", text_lower, re.IGNORECASE)
    if chol_match:
        result["cholesterol"] = float(chol_match.group(1))

    return result


@router.post("/health/ocr", response_model=HealthReportResponse)
async def upload_health_report(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    if not OCR_AVAILABLE:
        return HealthReportResponse(
            raw_text="OCR not available. Install: pip install pytesseract pillow"
        )

    try:
        contents = await file.read()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to read file: {str(e)}")

    if not contents:
        raise HTTPException(status_code=400, detail="Empty file")

    filename = (file.filename or "").lower()
    # Detect PDF by magic bytes if filename missing
    is_pdf = filename.endswith(".pdf") or contents[:4] == b"%PDF"

    try:
        if is_pdf:
            if not PDF_AVAILABLE:
                return HealthReportResponse(
                    raw_text="PDF support not available. Install: pip install pymupdf"
                )
            images = _pdf_to_images(contents)
            if not images:
                raise HTTPException(status_code=400, detail="PDF has no pages or could not be converted")
            all_text = []
            for img in images:
                all_text.append(pytesseract.image_to_string(img))
            text = "\n".join(all_text)
        else:
            image = Image.open(io.BytesIO(contents))
            image = image.convert("RGB")  # Ensure RGB for pytesseract
            text = pytesseract.image_to_string(image)
    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Processing failed: {str(e)}")

    parsed = parse_health_values(text)
    return HealthReportResponse(
        hba1c=parsed.get("hba1c"),
        cholesterol=parsed.get("cholesterol"),
        raw_text=text[:500] if text else None,
    )

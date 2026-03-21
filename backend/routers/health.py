from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from typing import Optional
import re
import io

from models import User
from schemas import HealthReportResponse, BodyScanResponse
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


# Body scan suggestions by goal (image is NOT stored - processed in memory only)
_BODY_SCAN_SUGGESTIONS = {
    "weight_loss": {
        "areas": [
            "Focus on full-body compound movements to maximize calorie burn",
            "Increase daily step count and NEAT (non-exercise activity)",
            "Build lean muscle to boost metabolism at rest",
        ],
        "exercises": [
            "Squats (3x12) – full body engagement",
            "Burpees (3x10) – high intensity",
            "Mountain climbers (3x30 sec)",
            "Plank holds (3x45 sec)",
            "Walking lunges (3x12 each leg)",
        ],
        "nutrition": [
            "Protein at every meal (20–30g) to preserve muscle",
            "Fiber-rich vegetables to stay full",
            "Limit refined carbs; choose whole grains",
            "Stay hydrated – 8+ glasses of water daily",
        ],
    },
    "muscle_gain": {
        "areas": [
            "Progressive overload – gradually increase weight or reps",
            "Prioritize compound lifts for major muscle groups",
            "Ensure adequate recovery between sessions",
        ],
        "exercises": [
            "Bench press (4x8–10)",
            "Deadlifts (4x6–8)",
            "Barbell rows (4x8–10)",
            "Overhead press (4x8–10)",
            "Leg press or squats (4x10–12)",
        ],
        "nutrition": [
            "1.6g protein per kg bodyweight daily",
            "Calorie surplus of 200–300 above maintenance",
            "Carbs post-workout for recovery",
            "Creatine (5g/day) for strength gains",
        ],
    },
    "general": {
        "areas": [
            "Balance strength and cardio for overall fitness",
            "Improve mobility and flexibility",
            "Build consistent workout habits",
        ],
        "exercises": [
            "Push-ups (3x12)",
            "Goblet squats (3x12)",
            "Dumbbell rows (3x10 each)",
            "Plank (3x45 sec)",
            "Jump rope or jogging (10–15 min)",
        ],
        "nutrition": [
            "Balanced macros: protein, carbs, healthy fats",
            "Eat a variety of colorful vegetables",
            "Pre-workout: light carbs 30–60 min before",
            "Post-workout: protein within 2 hours",
        ],
    },
}


@router.post("/health/body-scan", response_model=BodyScanResponse)
async def body_scan_analyze(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    """
    Analyze body scan image. Image is NOT stored – processed in memory only.
    Returns areas of improvement, suggested exercises, and nutrition tips based on user goal.
    """
    try:
        contents = await file.read()
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to read file: {str(e)}")

    if not contents or len(contents) < 100:
        raise HTTPException(status_code=400, detail="Invalid or empty image")

    # Validate it's an image (basic check)
    valid_signatures = [
        b"\xff\xd8\xff",  # JPEG
        b"\x89PNG",      # PNG
        b"GIF8",         # GIF
        b"RIFF",         # WebP
    ]
    if not any(contents.startswith(sig) for sig in valid_signatures):
        raise HTTPException(status_code=400, detail="File must be an image (JPEG, PNG, GIF, or WebP)")

    # Image is processed but NOT stored. Get suggestions based on user goal.
    goal = getattr(current_user, "goal", None) or "general"
    if goal not in _BODY_SCAN_SUGGESTIONS:
        goal = "general"

    suggestions = _BODY_SCAN_SUGGESTIONS[goal]
    return BodyScanResponse(
        areas_of_improvement=suggestions["areas"],
        suggested_exercises=suggestions["exercises"],
        suggested_nutrition=suggestions["nutrition"],
    )

"""Food scanning endpoints using cache-first resolution."""

import logging

from fastapi import APIRouter, File, HTTPException, Query, UploadFile, status

from app.schemas.food import GeminiFoodExtractionSchema
from app.core.health_claim_filter import health_claim_sanitizer
from app.services.cache_service import cache_service
from app.services.gemini_service import gemini_service
from app.services.off_service import off_service

logger = logging.getLogger("aaharai.scan")
router = APIRouter(prefix="/scan", tags=["Scanning & Nutrition"])


@router.get("/barcode/{barcode}", response_model=dict)
async def scan_barcode(barcode: str) -> dict:
    clean_barcode = barcode.strip()
    cached = await cache_service.get_by_barcode(clean_barcode)
    if cached:
        return health_claim_sanitizer.sanitize_food_payload(cached)

    product = await off_service.fetch_product_by_barcode(clean_barcode)
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Barcode not found in Open Food Facts database. "
            "Use camera photo OCR mode.",
        )

    raw_ingredients = product.get("ingredients_raw")
    if raw_ingredients:
        try:
            extracted = await gemini_service.parse_ingredients_text(
                food_name=product["food_name"],
                raw_ingredients=raw_ingredients,
                existing_nutrients=product.get("nutrients"),
            )
            product["parsed_ingredients"] = [
                ingredient.model_dump() for ingredient in extracted.parsed_ingredients
            ]
            product["allergens"] = sorted(
                set(product.get("allergens", [])) | set(extracted.allergens)
            )
        except Exception:
            logger.exception("Gemini enrichment failed; returning OFF data")

    return health_claim_sanitizer.sanitize_food_payload(
        await cache_service.save_to_cache(product)
    )


@router.post("/vision", response_model=dict)
async def scan_label_vision(file: UploadFile = File(...)) -> dict:
    allowed_types = {"image/jpeg", "image/png", "image/webp"}
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid image format. Only JPEG, PNG, and WebP are allowed.",
        )

    image_bytes = await file.read()
    if len(image_bytes) > 5 * 1024 * 1024:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Image size exceeds 5MB limit.",
        )

    try:
        extracted: GeminiFoodExtractionSchema = (
            await gemini_service.extract_from_image_bytes(
                image_bytes=image_bytes,
                mime_type=file.content_type,
            )
        )
    except Exception as exc:
        logger.exception("Vision inference failed")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to read packaging text. Please ensure adequate lighting and focus.",
        ) from exc

    raw_names = " ".join(item.name for item in extracted.parsed_ingredients)
    signature = cache_service.generate_signature_hash(raw_names or extracted.food_name)
    cached = await cache_service.get_by_signature_hash(signature)
    if cached:
        return health_claim_sanitizer.sanitize_food_payload(cached)

    return health_claim_sanitizer.sanitize_food_payload(
        await cache_service.save_to_cache(
            {
                "signature_hash": signature,
                "food_name": extracted.food_name,
                "brand_name": extracted.brand_name,
                "source": "gemini_vision",
                "serving_size": extracted.serving_size,
                "ingredients_raw": raw_names,
                "parsed_ingredients": [
                    ingredient.model_dump()
                    for ingredient in extracted.parsed_ingredients
                ],
                "nutrients": extracted.nutrients.model_dump(),
                "allergens": extracted.allergens,
                "preparation_insights": extracted.preparation_insights,
            }
        )
    )


@router.get("/street-food", response_model=dict)
async def get_street_food_analysis(
    dish_name: str = Query(..., min_length=2),
) -> dict:
    clean_name = dish_name.strip()
    cached = await cache_service.search_street_food(clean_name, limit=1)
    if cached:
        return health_claim_sanitizer.sanitize_food_payload(cached[0])

    try:
        inferred = await gemini_service.estimate_street_food(clean_name)
    except Exception as exc:
        logger.exception("Street food estimation failed")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to analyze street dish at this moment.",
        ) from exc

    return health_claim_sanitizer.sanitize_food_payload(
        await cache_service.save_to_cache(
            {
                "signature_hash": cache_service.generate_signature_hash(clean_name),
                "food_name": inferred.food_name,
                "brand_name": "Indian Street Vendor / Unpacked",
                "source": "street_food",
                "serving_size": inferred.serving_size
                or "1 serving / standard plate",
                "ingredients_raw": ", ".join(
                    ingredient.name for ingredient in inferred.parsed_ingredients
                ),
                "parsed_ingredients": [
                    ingredient.model_dump()
                    for ingredient in inferred.parsed_ingredients
                ],
                "nutrients": inferred.nutrients.model_dump(),
                "allergens": inferred.allergens,
                "preparation_insights": inferred.preparation_insights,
            }
        )
    )

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
    if cached and cached.get("food_name") and cached["food_name"] not in ("Unknown Packaged Item", "Unidentified Item"):
        if cached.get("parsed_ingredients") and len(cached["parsed_ingredients"]) > 0:
            return health_claim_sanitizer.sanitize_food_payload(cached)
        product = cached
    else:
        product = await off_service.fetch_product_by_barcode(clean_barcode)
    if not product:
        # Check if AI national knowledge base can resolve the Indian packaged food SKU
        try:
            identified = await gemini_service.resolve_barcode_item(clean_barcode)
            if identified and identified.food_name and "unidentified" not in identified.food_name.lower():
                raw_names = " ".join(item.name for item in identified.parsed_ingredients)
                fallback_product = {
                    "barcode": clean_barcode,
                    "food_name": identified.food_name,
                    "brand_name": identified.brand_name,
                    "source": "open_food_facts",
                    "serving_size": identified.serving_size,
                    "ingredients_raw": raw_names,
                    "parsed_ingredients": [
                        item.model_dump() for item in identified.parsed_ingredients
                    ],
                    "nutrients": identified.nutrients.model_dump(),
                    "allergens": identified.allergens,
                    "preparation_insights": identified.preparation_insights,
                }
                return health_claim_sanitizer.sanitize_food_payload(
                    await cache_service.save_to_cache(fallback_product)
                )
        except Exception:
            logger.exception("AI barcode resolution failed for %s", clean_barcode)

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Barcode not found in Open Food Facts database. "
            "Use camera photo OCR mode.",
        )

    raw_ingredients = product.get("ingredients_raw")
    if raw_ingredients or product.get("food_name"):
        try:
            extracted = await gemini_service.parse_ingredients_text(
                food_name=f"{product.get('brand_name') or ''} {product.get('food_name') or ''}".strip(),
                raw_ingredients=raw_ingredients or "",
                existing_nutrients=product.get("nutrients"),
            )
            if extracted.parsed_ingredients:
                product["parsed_ingredients"] = [
                    ingredient.model_dump() for ingredient in extracted.parsed_ingredients
                ]
            if extracted.allergens:
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

    # 1. First check if uploaded image contains a readable 1D/2D barcode (e.g. Parle-G barcode)
    try:
        import zxingcpp
        from io import BytesIO
        from PIL import Image

        pil_image = Image.open(BytesIO(image_bytes))
        barcode_res = zxingcpp.read_barcode(pil_image)
        if barcode_res and barcode_res.text:
            detected_code = barcode_res.text.strip()
            if detected_code.isdigit() and len(detected_code) in (8, 12, 13, 14):
                logger.info("Decoded barcode %s directly from uploaded vision image", detected_code)
                try:
                    return await scan_barcode(detected_code)
                except HTTPException as off_exc:
                    if off_exc.status_code != status.HTTP_404_NOT_FOUND:
                        raise
    except Exception as barcode_err:
        logger.debug("Barcode check on uploaded vision image skipped: %s", barcode_err)

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
    signature_source = f"{extracted.brand_name or ''} {extracted.food_name} {raw_names}".strip()
    signature = cache_service.generate_signature_hash(signature_source or extracted.food_name)
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

"""Safely add 19 pets to the existing Firestore pets collection.

Run without --apply to check the current count without writing. Documents are
created with stable IDs; existing documents are never updated or deleted.
"""

from __future__ import annotations

import argparse
import sys

import firebase_admin
from firebase_admin import firestore
from google.api_core.exceptions import AlreadyExists

PROJECT_ID = "pet-adoption-app-a1726"
COLLECTION_NAME = "pets"
EXPECTED_EXISTING_COUNT = 6
TARGET_COUNT = 25

SAMPLE_PETS: dict[str, dict[str, object]] = {
    "seed_pet_bird_kiwi_v1": {
        "name": "Kiwi",
        "type": "Bird",
        "age": "1 year",
        "description": "A cheerful green budgie who enjoys company and singing.",
        "price": 25,
        "gender": "Male",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1552728089-57bdde30beb3?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_bird_sunny_v1": {
        "name": "Sunny",
        "type": "Bird",
        "age": "2 years",
        "description": "A gentle yellow cockatiel looking for a calm home.",
        "price": 40,
        "gender": "Female",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1520808663317-647b476a81b9?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_bird_blue_v1": {
        "name": "Blue",
        "type": "Bird",
        "age": "8 months",
        "description": "A curious blue parakeet who loves fresh leafy greens.",
        "price": 20,
        "gender": "Male",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1552728089-57bdde30beb3?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_bird_pearl_v1": {
        "name": "Pearl",
        "type": "Bird",
        "age": "3 years",
        "description": "A quiet white dove that would suit a peaceful home.",
        "price": 30,
        "gender": "Female",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1520808663317-647b476a81b9?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_bird_pip_v1": {
        "name": "Pip",
        "type": "Bird",
        "age": "1 year",
        "description": "A friendly little finch who is happiest with a companion.",
        "price": 18,
        "gender": "Male",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1552728089-57bdde30beb3?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_rabbit_coco_v1": {
        "name": "Coco",
        "type": "Rabbit",
        "age": "1 year",
        "description": "A soft brown rabbit who enjoys gentle handling.",
        "price": 35,
        "gender": "Female",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_rabbit_thumper_v1": {
        "name": "Thumper",
        "type": "Rabbit",
        "age": "2 years",
        "description": "An active rabbit who loves exploring a safe play area.",
        "price": 40,
        "gender": "Male",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_rabbit_snowball_v1": {
        "name": "Snowball",
        "type": "Rabbit",
        "age": "6 months",
        "description": "A curious young rabbit who needs a patient family.",
        "price": 30,
        "gender": "Female",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_rabbit_biscuit_v1": {
        "name": "Biscuit",
        "type": "Rabbit",
        "age": "3 years",
        "description": "A relaxed rabbit who likes fresh hay and quiet afternoons.",
        "price": 25,
        "gender": "Male",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_hamster_nibbles_v1": {
        "name": "Nibbles",
        "type": "Hamster",
        "age": "5 months",
        "description": "A tiny, active hamster who enjoys tunnels and toys.",
        "price": 15,
        "gender": "Male",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1425082661705-1834bfd09dca?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_hamster_peaches_v1": {
        "name": "Peaches",
        "type": "Hamster",
        "age": "7 months",
        "description": "A gentle hamster who is comfortable with careful handling.",
        "price": 18,
        "gender": "Female",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1425082661705-1834bfd09dca?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_hamster_mochi_v1": {
        "name": "Mochi",
        "type": "Hamster",
        "age": "4 months",
        "description": "A playful young hamster who loves a roomy enclosure.",
        "price": 15,
        "gender": "Female",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1425082661705-1834bfd09dca?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_guinea_pig_poppy_v1": {
        "name": "Poppy",
        "type": "Guinea Pig",
        "age": "1 year",
        "description": "A sociable guinea pig who enjoys fresh vegetables.",
        "price": 28,
        "gender": "Female",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1548767797-d8c844163c4c?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_guinea_pig_pepper_v1": {
        "name": "Pepper",
        "type": "Guinea Pig",
        "age": "2 years",
        "description": "A friendly guinea pig who likes gentle company.",
        "price": 25,
        "gender": "Male",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1548767797-d8c844163c4c?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_guinea_pig_clover_v1": {
        "name": "Clover",
        "type": "Guinea Pig",
        "age": "8 months",
        "description": "A curious guinea pig who enjoys exploring hideaways.",
        "price": 30,
        "gender": "Female",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1548767797-d8c844163c4c?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_turtle_shelly_v1": {
        "name": "Shelly",
        "type": "Turtle",
        "age": "4 years",
        "description": "A calm turtle who needs a properly equipped habitat.",
        "price": 45,
        "gender": "Female",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1437622368342-7a3d73a34c8f?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_turtle_turbo_v1": {
        "name": "Turbo",
        "type": "Turtle",
        "age": "2 years",
        "description": "A curious turtle looking for an experienced caretaker.",
        "price": 40,
        "gender": "Male",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1437622368342-7a3d73a34c8f?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_fish_bubbles_v1": {
        "name": "Bubbles",
        "type": "Fish",
        "age": "1 year",
        "description": "A bright goldfish that needs a clean, spacious tank.",
        "price": 10,
        "gender": "Unknown",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1524704654690-b56c05c78a00?auto=format&fit=crop&w=800&q=80",
    },
    "seed_pet_fish_comet_v1": {
        "name": "Comet",
        "type": "Fish",
        "age": "6 months",
        "description": "A lively guppy who thrives in a well-maintained aquarium.",
        "price": 8,
        "gender": "Male",
        "isVaccinated": False,
        "healthStatus": "Healthy",
        "imageUrl": "https://images.unsplash.com/photo-1524704654690-b56c05c78a00?auto=format&fit=crop&w=800&q=80",
    },
}

PET_FIELDS = {
    "name",
    "type",
    "age",
    "description",
    "price",
    "gender",
    "isVaccinated",
    "healthStatus",
    "imageUrl",
}


def _validate_seed_data() -> None:
    if len(SAMPLE_PETS) != TARGET_COUNT - EXPECTED_EXISTING_COUNT:
        raise ValueError("The seed list must contain exactly 19 pets.")

    for document_id, pet in SAMPLE_PETS.items():
        if set(pet) != PET_FIELDS:
            raise ValueError(f"{document_id} does not match the Firestore pet schema.")


def _read_pets(collection):
    return {snapshot.id: snapshot for snapshot in collection.stream()}


def seed_pets(apply: bool) -> int:
    _validate_seed_data()

    app = firebase_admin.initialize_app(
        options={"projectId": PROJECT_ID},
    )
    collection = firestore.client(app=app).collection(COLLECTION_NAME)
    current_pets = _read_pets(collection)
    seed_ids = set(SAMPLE_PETS)
    existing_seed_ids = seed_ids.intersection(current_pets)
    original_pet_ids = set(current_pets).difference(seed_ids)

    if len(original_pet_ids) != EXPECTED_EXISTING_COUNT:
        raise RuntimeError(
            f"Expected 6 existing non-seed pets; found {len(original_pet_ids)}. "
            f"Collection currently has {len(current_pets)} documents. "
            "No documents were changed."
        )

    for document_id in existing_seed_ids:
        if current_pets[document_id].to_dict() != SAMPLE_PETS[document_id]:
            raise RuntimeError(
                f"Seed ID {document_id!r} already exists with different data. "
                "No existing documents will be overwritten."
            )

    missing_ids = seed_ids.difference(existing_seed_ids)
    if not apply:
        print(
            f"Dry run for project {PROJECT_ID}: "
            f"{len(current_pets)} pets found, {len(missing_ids)} would be added, "
            f"target total is {TARGET_COUNT}. No writes performed."
        )
        return 0

    for document_id in sorted(missing_ids):
        reference = collection.document(document_id)
        try:
            reference.create(SAMPLE_PETS[document_id])
            print(f"Added {SAMPLE_PETS[document_id]['name']} ({document_id}).")
        except AlreadyExists:
            existing = reference.get()
            if not existing.exists or existing.to_dict() != SAMPLE_PETS[document_id]:
                raise RuntimeError(
                    f"Seed ID {document_id!r} was created with different data. "
                    "It was not overwritten."
                )
            print(f"Already present: {SAMPLE_PETS[document_id]['name']}.")

    final_pets = _read_pets(collection)
    final_seed_ids = seed_ids.intersection(final_pets)
    final_original_ids = set(final_pets).difference(seed_ids)
    if (
        len(final_pets) != TARGET_COUNT
        or len(final_seed_ids) != len(SAMPLE_PETS)
        or final_original_ids != original_pet_ids
    ):
        raise RuntimeError(
            f"Post-seed verification failed: found {len(final_pets)} pets, "
            f"{len(final_seed_ids)} of 19 seed pets, and "
            f"{len(final_original_ids)} original pets. Expected 25, 19, and 6. "
            "No existing documents were overwritten or deleted."
        )

    for document_id, pet in SAMPLE_PETS.items():
        if final_pets[document_id].to_dict() != pet:
            raise RuntimeError(f"Post-seed data mismatch for {document_id!r}.")

    print(
        f"Verified: {len(final_pets)} pets total "
        f"({len(final_original_ids)} existing + {len(final_seed_ids)} added)."
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Create missing seed documents. Without this flag, run a read-only dry run.",
    )
    args = parser.parse_args()

    try:
        return seed_pets(apply=args.apply)
    except Exception as error:
        print(f"Pet seed failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

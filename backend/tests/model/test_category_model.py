from app import db
from app.models import Category, Household, Item


def _make_household() -> Household:
    return Household(name="testhousehold").save()


def _make_item(name: str, category: Category | None) -> Item:
    return Item(
        name=name,
        household_id=category.household_id,
        category=category,
    ).save()


def test_delete_category_sets_item_category_id_to_null(db_session):
    """Deleting a category must uncategorize its items, not violate the FK.

    SQLite runs with `PRAGMA foreign_keys=ON` in this suite, so a delete
    that leaves dangling `item.category_id` values would fail instead.
    """
    household = _make_household()
    category = Category(name="Pantry", household=household).save()
    item = _make_item("Flour", category)
    assert item.category_id == category.id

    category.delete()

    assert Category.find_by_id(category.id) is None
    assert Item.find_by_id(item.id).category_id is None


def test_category_merge_reassigns_items(db_session):
    """`self.merge(other)` folds `other` into `self`: other's items are
    reassigned and `other` is deleted — the controller passes the kept
    category as `self` and the duplicate as `merge_category_id`."""
    household = _make_household()
    kept = Category(name="Groceries", household=household).save()
    duplicate = Category(name="Grocerries", household=household).save()
    item = _make_item("Milk", duplicate)

    kept.merge(duplicate)
    db.session.commit()

    assert Item.find_by_id(item.id).category_id == kept.id
    assert Category.find_by_id(duplicate.id) is None

# Changelog

All notable changes to this fork of [KitchenOwl](https://github.com/TomBursch/kitchenowl)
are documented in this file, on top of upstream version 0.7.10.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and versioning follows [SemVer](https://semver.org/).

**Convention:** update `[Unreleased]` in the commit that completes a feature.
For multi-commit features, that's the final commit. For single-commit
features, that's the same commit.

## [Unreleased]

### Added

- Inline shopping-list management from the main-view header: add, rename, and
  delete lists via the add field and a long-press action sheet (rename is
  available for every list; delete only for non-default lists)
- `isDefault` flag on the shopping-list client model and API responses; list
  deletion is gated on it, falling back to treating the first list as the
  default when the server does not send the flag
- Error snackbar when shopping-list deletion fails

### Changed

- Shopping-list renames now propagate in real time: the backend emits a
  `shoppinglist:update` Socket.IO event to the household room, and clients
  refresh on it (previously other clients waited for the 30s periodic refresh)

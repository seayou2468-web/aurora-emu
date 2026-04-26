# Phase 1: Standard Library Serialization Core

This phase introduces a Boost-free serialization core built on C++ standard library I/O streams.

## Added

- `std_archive.h`
  - `BinaryOutputArchive` / `BinaryInputArchive`
  - `save_binary` / `load_binary`
  - serializers for primitives, enums, string, array, vector, deque, list, set, map,
    unordered_map, optional, variant, unique_ptr, shared_ptr
  - `BinaryBlob` + `make_binary_object`
  - `PolymorphicRegistry<Base>` for type factory registration and restore-time object creation

## Goal of this phase

Build a functional, non-stub serialization engine that can be wired into HLE in follow-up phases,
without requiring Boost archive types.

## Non-goals for this phase

- Rewiring all existing HLE serialization call sites
- Legacy savestate format compatibility layer
- Full replacement of Boost export/registration macros

Those are covered by later migration phases.

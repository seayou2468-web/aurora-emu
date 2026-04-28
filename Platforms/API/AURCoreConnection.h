#pragma once

#include <string.h>

#include "AUREmulatorCoreAPI.h"

typedef enum AURCoreConnectionKind {
  AUR_CORE_CONNECTION_MODULE_ADAPTER = 0,
  AUR_CORE_CONNECTION_BRIDGE = 1,
} AURCoreConnectionKind;

static inline AURCoreConnectionKind AURCoreConnectionKindForCoreName(const char* core_name) {
  if (core_name != NULL && strcmp(core_name, "aurora3ds") == 0) {
    return AUR_CORE_CONNECTION_BRIDGE;
  }
  return AUR_CORE_CONNECTION_MODULE_ADAPTER;
}

static inline AURCoreConnectionKind AURCoreConnectionKindForCoreType(EmulatorCoreType core_type) {
  return AURCoreConnectionKindForCoreName(EmulatorCoreTypeName(core_type));
}

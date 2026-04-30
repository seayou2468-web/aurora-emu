#pragma once

#include <string.h>

#include "AUREmulatorCoreAPI.h"

typedef enum AURCoreConnectionKind {
  AUR_CORE_CONNECTION_MODULE_ADAPTER = 0,
  AUR_CORE_CONNECTION_BRIDGE = 1,
} AURCoreConnectionKind;

static inline AURCoreConnectionKind AURCoreConnectionKindForCoreName(const char* core_name) {
  (void)core_name;
  return AUR_CORE_CONNECTION_MODULE_ADAPTER;
}

static inline AURCoreConnectionKind AURCoreConnectionKindForCoreType(EmulatorCoreType core_type) {
  return AURCoreConnectionKindForCoreName(EmulatorCoreTypeName(core_type));
}

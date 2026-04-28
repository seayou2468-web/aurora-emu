#include "core_adapter.hpp"

namespace core {

extern const CoreAdapter kGBAAdapter;
extern const CoreAdapter kQuickNesAdapter;
extern const CoreAdapter kSameBoyAdapter;
extern const CoreAdapter kMelonDSAdapter;
extern const CoreAdapter kAurora3DSAdapter;

const CoreAdapter* FindCoreAdapter(EmulatorCoreType type) {
#if defined(AURORA_IOS_MINIMAL_CORE) || defined(AURORA_LINUX_3DS_ONLY)
  switch (type) {
    case EMULATOR_CORE_TYPE_3DS:
      return &kAurora3DSAdapter;
    default:
      return nullptr;
  }
#else
  switch (type) {
    case EMULATOR_CORE_TYPE_GBA:
      return &kGBAAdapter;
    case EMULATOR_CORE_TYPE_NES:
      return &kQuickNesAdapter;
    case EMULATOR_CORE_TYPE_GB:
      return &kSameBoyAdapter;
    case EMULATOR_CORE_TYPE_NDS:
      return &kMelonDSAdapter;
    case EMULATOR_CORE_TYPE_3DS:
      return &kAurora3DSAdapter;
    default:
      return nullptr;
  }
#endif
}

}  // namespace core

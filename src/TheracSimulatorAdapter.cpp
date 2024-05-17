#pragma comment(lib, "hstherac25.dll")
#include "TheracSimulatorAdapter.hpp"
#include <HsTherac25_stub.h>
#include <cstring>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <gsl/gsl>
#include <mutex>
#include <ranges>
namespace TheracSimulatorAdapter {
using std::ranges::ssize;

auto TheracSimulatorAdapter::hs_init(godot::String const & args
) -> HsStablePtr {
  //  auto _argv   = std::string_view(std::views::split(args, ' '));
  auto _argv   = args.split(" ");
  int argc     = ssize(_argv);
  int i        = 0;
  char ** argv = new char *[argc + 1];
  argv[argc]   = nullptr;

  for (auto const & hng : _argv) {
    // chz figured out wtf char *** argv is supposed to be for me in this
    // context
    for (i = 0; i < argc; i++) {
      argv[i] = new char[hng.length() + 1];
      strcpy(argv[i], hng.utf8());
    }
  }
  ::hs_init(&argc, &argv);
  return ::startMachine();
}
TheracSimulatorAdapter::TheracSimulatorAdapter() { wrapped_comms = hs_init(); }
void TheracSimulatorAdapter::hs_exit() { ::hs_exit(); }
TheracSimulatorAdapter::~TheracSimulatorAdapter() {
  hs_exit();
  wrapped_comms = nullptr;
  delete this;
}
void TheracSimulatorAdapter::externalCallWrap(
    ExtCallType ext_call_type,
    BeamType beam_type,
    CollimatorPosition collimator_position,
    HsInt beam_energy
) {
  ::externalCallWrap(
      wrapped_comms,
      ext_call_type,
      beam_type,
      collimator_position,
      beam_energy
  );
}
auto TheracSimulatorAdapter::requestStateInfo(
    StateInfoRequest state_info_request
) -> godot::String {
  return static_cast<char const *>(
      ::requestStateInfo(wrapped_comms, state_info_request)
  );
}
auto TheracSimulatorAdapter::check_malfunction() -> bool {
  std::shared_lock<std::shared_mutex> lock{malfunctioning_mutex};
  return malfunctioning;
}
auto TheracSimulatorAdapter::set_malfunction() -> bool {
  std::unique_lock<std::shared_mutex> lock{malfunctioning_mutex};
  return malfunctioning = true;
}
auto TheracSimulatorAdapter::reset_malfunction() -> bool {
  std::unique_lock<std::shared_mutex> lock{malfunctioning_mutex};
  return not(malfunctioning = false);
}

} // namespace TheracSimulatorAdapter

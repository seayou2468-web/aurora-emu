// Copyright Citra Emulator Project / Azahar Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#pragma once

#include <array>
#include <string_view>

namespace Settings {

namespace Keys {
static constexpr char PrivateKey[] = "PrivateKey";
static constexpr char PublicKey[] = "PublicKey";
static constexpr char allow_plugin_loader[] = "allow_plugin_loader";
static constexpr char anaglyph_shader_name[] = "anaglyph_shader_name";
static constexpr char apply_region_free_patch[] = "apply_region_free_patch";
static constexpr char aspect_ratio[] = "aspect_ratio";
static constexpr char async_custom_loading[] = "async_custom_loading";
static constexpr char async_presentation[] = "async_presentation";
static constexpr char async_shader_compilation[] = "async_shader_compilation";
static constexpr char audio_emulation[] = "audio_emulation";
static constexpr char bg_blue[] = "bg_blue";
static constexpr char bg_green[] = "bg_green";
static constexpr char bg_red[] = "bg_red";
static constexpr char cardboard_screen_size[] = "cardboard_screen_size";
static constexpr char cardboard_x_shift[] = "cardboard_x_shift";
static constexpr char cardboard_y_shift[] = "cardboard_y_shift";
static constexpr char compress_cia_installs[] = "compress_cia_installs";
static constexpr char cpu_clock_percentage[] = "cpu_clock_percentage";
static constexpr char custom_bottom_height[] = "custom_bottom_height";
static constexpr char custom_bottom_width[] = "custom_bottom_width";
static constexpr char custom_bottom_x[] = "custom_bottom_x";
static constexpr char custom_bottom_y[] = "custom_bottom_y";
static constexpr char custom_portrait_bottom_height[] = "custom_portrait_bottom_height";
static constexpr char custom_portrait_bottom_width[] = "custom_portrait_bottom_width";
static constexpr char custom_portrait_bottom_x[] = "custom_portrait_bottom_x";
static constexpr char custom_portrait_bottom_y[] = "custom_portrait_bottom_y";
static constexpr char custom_portrait_top_height[] = "custom_portrait_top_height";
static constexpr char custom_portrait_top_width[] = "custom_portrait_top_width";
static constexpr char custom_portrait_top_x[] = "custom_portrait_top_x";
static constexpr char custom_portrait_top_y[] = "custom_portrait_top_y";
static constexpr char custom_second_layer_opacity[] = "custom_second_layer_opacity";
static constexpr char custom_textures[] = "custom_textures";
static constexpr char custom_top_height[] = "custom_top_height";
static constexpr char custom_top_width[] = "custom_top_width";
static constexpr char custom_top_x[] = "custom_top_x";
static constexpr char custom_top_y[] = "custom_top_y";
static constexpr char delay_game_render_thread_us[] = "delay_game_render_thread_us";
static constexpr char delay_start_for_lle_modules[] = "delay_start_for_lle_modules";
static constexpr char deterministic_async_operations[] = "deterministic_async_operations";
static constexpr char disable_right_eye_render[] = "disable_right_eye_render";
static constexpr char disable_spirv_optimizer[] = "disable_spirv_optimizer";
static constexpr char dump_command_buffers[] = "dump_command_buffers";
static constexpr char dump_textures[] = "dump_textures";
static constexpr char enable_audio_stretching[] = "enable_audio_stretching";
static constexpr char enable_gamemode[] = "enable_gamemode";
static constexpr char enable_realtime_audio[] = "enable_realtime_audio";
static constexpr char enable_required_online_lle_modules[] = "enable_required_online_lle_modules";
static constexpr char enable_rpc_server[] = "enable_rpc_server";
static constexpr char factor_3d[] = "factor_3d";
static constexpr char filter_mode[] = "filter_mode";
static constexpr char frame_limit[] = "frame_limit";
static constexpr char gdbstub_port[] = "gdbstub_port";
static constexpr char graphics_api[] = "graphics_api";
static constexpr char init_clock[] = "init_clock";
static constexpr char init_ticks_override[] = "init_ticks_override";
static constexpr char init_ticks_type[] = "init_ticks_type";
static constexpr char init_time[] = "init_time";
static constexpr char init_time_offset[] = "init_time_offset";
static constexpr char input_device[] = "input_device";
static constexpr char input_type[] = "input_type";
static constexpr char instant_debug_log[] = "instant_debug_log";
static constexpr char is_new_3ds[] = "is_new_3ds";
static constexpr char large_screen_proportion[] = "large_screen_proportion";
static constexpr char layout_option[] = "layout_option";
static constexpr char layouts_to_cycle[] = "layouts_to_cycle";
static constexpr char lle_applets[] = "lle_applets";
static constexpr char log_filter[] = "log_filter";
static constexpr char log_regex_filter[] = "log_regex_filter";
static constexpr char mono_render_option[] = "mono_render_option";
static constexpr char output_device[] = "output_device";
static constexpr char output_type[] = "output_type";
static constexpr char physical_device[] = "physical_device";
static constexpr char plugin_loader[] = "plugin_loader";
static constexpr char portrait_layout_option[] = "portrait_layout_option";
static constexpr char pp_shader_name[] = "pp_shader_name";
static constexpr char preload_textures[] = "preload_textures";
static constexpr char region_value[] = "region_value";
static constexpr char render_3d[] = "render_3d";
static constexpr char render_3d_which_display[] = "render_3d_which_display";
static constexpr char renderer_debug[] = "renderer_debug";
static constexpr char resolution_factor[] = "resolution_factor";
static constexpr char screen_bottom_leftright_padding[] = "screen_bottom_leftright_padding";
static constexpr char screen_bottom_stretch[] = "screen_bottom_stretch";
static constexpr char screen_bottom_topbottom_padding[] = "screen_bottom_topbottom_padding";
static constexpr char screen_gap[] = "screen_gap";
static constexpr char screen_top_leftright_padding[] = "screen_top_leftright_padding";
static constexpr char screen_top_stretch[] = "screen_top_stretch";
static constexpr char screen_top_topbottom_padding[] = "screen_top_topbottom_padding";
static constexpr char secondary_display_layout[] = "secondary_display_layout";
static constexpr char shaders_accurate_mul[] = "shaders_accurate_mul";
static constexpr char small_screen_position[] = "small_screen_position";
static constexpr char spirv_shader_gen[] = "spirv_shader_gen";
static constexpr char steps_per_hour[] = "steps_per_hour";
static constexpr char swap_eyes_3d[] = "swap_eyes_3d";
static constexpr char swap_screen[] = "swap_screen";
static constexpr char texture_filter[] = "texture_filter";
static constexpr char texture_sampling[] = "texture_sampling";
static constexpr char toggle_unique_data_console_type[] = "toggle_unique_data_console_type";
static constexpr char turbo_limit[] = "turbo_limit";
static constexpr char upright_screen[] = "upright_screen";
static constexpr char use_artic_base_controller[] = "use_artic_base_controller";
static constexpr char use_custom_storage[] = "use_custom_storage";
static constexpr char use_disk_shader_cache[] = "use_disk_shader_cache";
static constexpr char use_display_refresh_rate_detection[] = "use_display_refresh_rate_detection";
static constexpr char use_gdbstub[] = "use_gdbstub";
static constexpr char use_gles[] = "use_gles";
static constexpr char use_hw_shader[] = "use_hw_shader";
static constexpr char use_integer_scaling[] = "use_integer_scaling";
static constexpr char use_virtual_sd[] = "use_virtual_sd";
static constexpr char use_vsync[] = "use_vsync";
static constexpr char volume[] = "volume";

static constexpr std::array keys_array = {
    PrivateKey,
    PublicKey,
    allow_plugin_loader,
    anaglyph_shader_name,
    apply_region_free_patch,
    aspect_ratio,
    async_custom_loading,
    async_presentation,
    async_shader_compilation,
    audio_emulation,
    bg_blue,
    bg_green,
    bg_red,
    cardboard_screen_size,
    cardboard_x_shift,
    cardboard_y_shift,
    compress_cia_installs,
    cpu_clock_percentage,
    custom_bottom_height,
    custom_bottom_width,
    custom_bottom_x,
    custom_bottom_y,
    custom_portrait_bottom_height,
    custom_portrait_bottom_width,
    custom_portrait_bottom_x,
    custom_portrait_bottom_y,
    custom_portrait_top_height,
    custom_portrait_top_width,
    custom_portrait_top_x,
    custom_portrait_top_y,
    custom_second_layer_opacity,
    custom_textures,
    custom_top_height,
    custom_top_width,
    custom_top_x,
    custom_top_y,
    delay_game_render_thread_us,
    delay_start_for_lle_modules,
    deterministic_async_operations,
    disable_right_eye_render,
    disable_spirv_optimizer,
    dump_command_buffers,
    dump_textures,
    enable_audio_stretching,
    enable_gamemode,
    enable_realtime_audio,
    enable_required_online_lle_modules,
    enable_rpc_server,
    factor_3d,
    filter_mode,
    frame_limit,
    gdbstub_port,
    graphics_api,
    init_clock,
    init_ticks_override,
    init_ticks_type,
    init_time,
    init_time_offset,
    input_device,
    input_type,
    instant_debug_log,
    is_new_3ds,
    large_screen_proportion,
    layout_option,
    layouts_to_cycle,
    lle_applets,
    log_filter,
    log_regex_filter,
    mono_render_option,
    output_device,
    output_type,
    physical_device,
    plugin_loader,
    portrait_layout_option,
    pp_shader_name,
    preload_textures,
    region_value,
    render_3d,
    render_3d_which_display,
    renderer_debug,
    resolution_factor,
    screen_bottom_leftright_padding,
    screen_bottom_stretch,
    screen_bottom_topbottom_padding,
    screen_gap,
    screen_top_leftright_padding,
    screen_top_stretch,
    screen_top_topbottom_padding,
    secondary_display_layout,
    shaders_accurate_mul,
    small_screen_position,
    spirv_shader_gen,
    steps_per_hour,
    swap_eyes_3d,
    swap_screen,
    texture_filter,
    texture_sampling,
    toggle_unique_data_console_type,
    turbo_limit,
    upright_screen,
    use_artic_base_controller,
    use_custom_storage,
    use_disk_shader_cache,
    use_display_refresh_rate_detection,
    use_gdbstub,
    use_gles,
    use_hw_shader,
    use_integer_scaling,
    use_virtual_sd,
    use_vsync,
    volume,
};
}

namespace HKeys {
static constexpr auto PrivateKey = std::string_view{"PrivateKey"};
static constexpr auto PublicKey = std::string_view{"PublicKey"};
static constexpr auto allow_plugin_loader = std::string_view{"allow_plugin_loader"};
static constexpr auto anaglyph_shader_name = std::string_view{"anaglyph_shader_name"};
static constexpr auto apply_region_free_patch = std::string_view{"apply_region_free_patch"};
static constexpr auto aspect_ratio = std::string_view{"aspect_ratio"};
static constexpr auto async_custom_loading = std::string_view{"async_custom_loading"};
static constexpr auto async_presentation = std::string_view{"async_presentation"};
static constexpr auto async_shader_compilation = std::string_view{"async_shader_compilation"};
static constexpr auto audio_emulation = std::string_view{"audio_emulation"};
static constexpr auto bg_blue = std::string_view{"bg_blue"};
static constexpr auto bg_green = std::string_view{"bg_green"};
static constexpr auto bg_red = std::string_view{"bg_red"};
static constexpr auto cardboard_screen_size = std::string_view{"cardboard_screen_size"};
static constexpr auto cardboard_x_shift = std::string_view{"cardboard_x_shift"};
static constexpr auto cardboard_y_shift = std::string_view{"cardboard_y_shift"};
static constexpr auto compress_cia_installs = std::string_view{"compress_cia_installs"};
static constexpr auto cpu_clock_percentage = std::string_view{"cpu_clock_percentage"};
static constexpr auto custom_bottom_height = std::string_view{"custom_bottom_height"};
static constexpr auto custom_bottom_width = std::string_view{"custom_bottom_width"};
static constexpr auto custom_bottom_x = std::string_view{"custom_bottom_x"};
static constexpr auto custom_bottom_y = std::string_view{"custom_bottom_y"};
static constexpr auto custom_portrait_bottom_height = std::string_view{"custom_portrait_bottom_height"};
static constexpr auto custom_portrait_bottom_width = std::string_view{"custom_portrait_bottom_width"};
static constexpr auto custom_portrait_bottom_x = std::string_view{"custom_portrait_bottom_x"};
static constexpr auto custom_portrait_bottom_y = std::string_view{"custom_portrait_bottom_y"};
static constexpr auto custom_portrait_top_height = std::string_view{"custom_portrait_top_height"};
static constexpr auto custom_portrait_top_width = std::string_view{"custom_portrait_top_width"};
static constexpr auto custom_portrait_top_x = std::string_view{"custom_portrait_top_x"};
static constexpr auto custom_portrait_top_y = std::string_view{"custom_portrait_top_y"};
static constexpr auto custom_second_layer_opacity = std::string_view{"custom_second_layer_opacity"};
static constexpr auto custom_textures = std::string_view{"custom_textures"};
static constexpr auto custom_top_height = std::string_view{"custom_top_height"};
static constexpr auto custom_top_width = std::string_view{"custom_top_width"};
static constexpr auto custom_top_x = std::string_view{"custom_top_x"};
static constexpr auto custom_top_y = std::string_view{"custom_top_y"};
static constexpr auto delay_game_render_thread_us = std::string_view{"delay_game_render_thread_us"};
static constexpr auto delay_start_for_lle_modules = std::string_view{"delay_start_for_lle_modules"};
static constexpr auto deterministic_async_operations = std::string_view{"deterministic_async_operations"};
static constexpr auto disable_right_eye_render = std::string_view{"disable_right_eye_render"};
static constexpr auto disable_spirv_optimizer = std::string_view{"disable_spirv_optimizer"};
static constexpr auto dump_command_buffers = std::string_view{"dump_command_buffers"};
static constexpr auto dump_textures = std::string_view{"dump_textures"};
static constexpr auto enable_audio_stretching = std::string_view{"enable_audio_stretching"};
static constexpr auto enable_gamemode = std::string_view{"enable_gamemode"};
static constexpr auto enable_realtime_audio = std::string_view{"enable_realtime_audio"};
static constexpr auto enable_required_online_lle_modules = std::string_view{"enable_required_online_lle_modules"};
static constexpr auto enable_rpc_server = std::string_view{"enable_rpc_server"};
static constexpr auto factor_3d = std::string_view{"factor_3d"};
static constexpr auto filter_mode = std::string_view{"filter_mode"};
static constexpr auto frame_limit = std::string_view{"frame_limit"};
static constexpr auto gdbstub_port = std::string_view{"gdbstub_port"};
static constexpr auto graphics_api = std::string_view{"graphics_api"};
static constexpr auto init_clock = std::string_view{"init_clock"};
static constexpr auto init_ticks_override = std::string_view{"init_ticks_override"};
static constexpr auto init_ticks_type = std::string_view{"init_ticks_type"};
static constexpr auto init_time = std::string_view{"init_time"};
static constexpr auto init_time_offset = std::string_view{"init_time_offset"};
static constexpr auto input_device = std::string_view{"input_device"};
static constexpr auto input_type = std::string_view{"input_type"};
static constexpr auto instant_debug_log = std::string_view{"instant_debug_log"};
static constexpr auto is_new_3ds = std::string_view{"is_new_3ds"};
static constexpr auto large_screen_proportion = std::string_view{"large_screen_proportion"};
static constexpr auto layout_option = std::string_view{"layout_option"};
static constexpr auto layouts_to_cycle = std::string_view{"layouts_to_cycle"};
static constexpr auto lle_applets = std::string_view{"lle_applets"};
static constexpr auto log_filter = std::string_view{"log_filter"};
static constexpr auto log_regex_filter = std::string_view{"log_regex_filter"};
static constexpr auto mono_render_option = std::string_view{"mono_render_option"};
static constexpr auto output_device = std::string_view{"output_device"};
static constexpr auto output_type = std::string_view{"output_type"};
static constexpr auto physical_device = std::string_view{"physical_device"};
static constexpr auto plugin_loader = std::string_view{"plugin_loader"};
static constexpr auto portrait_layout_option = std::string_view{"portrait_layout_option"};
static constexpr auto pp_shader_name = std::string_view{"pp_shader_name"};
static constexpr auto preload_textures = std::string_view{"preload_textures"};
static constexpr auto region_value = std::string_view{"region_value"};
static constexpr auto render_3d = std::string_view{"render_3d"};
static constexpr auto render_3d_which_display = std::string_view{"render_3d_which_display"};
static constexpr auto renderer_debug = std::string_view{"renderer_debug"};
static constexpr auto resolution_factor = std::string_view{"resolution_factor"};
static constexpr auto screen_bottom_leftright_padding = std::string_view{"screen_bottom_leftright_padding"};
static constexpr auto screen_bottom_stretch = std::string_view{"screen_bottom_stretch"};
static constexpr auto screen_bottom_topbottom_padding = std::string_view{"screen_bottom_topbottom_padding"};
static constexpr auto screen_gap = std::string_view{"screen_gap"};
static constexpr auto screen_top_leftright_padding = std::string_view{"screen_top_leftright_padding"};
static constexpr auto screen_top_stretch = std::string_view{"screen_top_stretch"};
static constexpr auto screen_top_topbottom_padding = std::string_view{"screen_top_topbottom_padding"};
static constexpr auto secondary_display_layout = std::string_view{"secondary_display_layout"};
static constexpr auto shaders_accurate_mul = std::string_view{"shaders_accurate_mul"};
static constexpr auto small_screen_position = std::string_view{"small_screen_position"};
static constexpr auto spirv_shader_gen = std::string_view{"spirv_shader_gen"};
static constexpr auto steps_per_hour = std::string_view{"steps_per_hour"};
static constexpr auto swap_eyes_3d = std::string_view{"swap_eyes_3d"};
static constexpr auto swap_screen = std::string_view{"swap_screen"};
static constexpr auto texture_filter = std::string_view{"texture_filter"};
static constexpr auto texture_sampling = std::string_view{"texture_sampling"};
static constexpr auto toggle_unique_data_console_type = std::string_view{"toggle_unique_data_console_type"};
static constexpr auto turbo_limit = std::string_view{"turbo_limit"};
static constexpr auto upright_screen = std::string_view{"upright_screen"};
static constexpr auto use_artic_base_controller = std::string_view{"use_artic_base_controller"};
static constexpr auto use_custom_storage = std::string_view{"use_custom_storage"};
static constexpr auto use_disk_shader_cache = std::string_view{"use_disk_shader_cache"};
static constexpr auto use_display_refresh_rate_detection = std::string_view{"use_display_refresh_rate_detection"};
static constexpr auto use_gdbstub = std::string_view{"use_gdbstub"};
static constexpr auto use_gles = std::string_view{"use_gles"};
static constexpr auto use_hw_shader = std::string_view{"use_hw_shader"};
static constexpr auto use_integer_scaling = std::string_view{"use_integer_scaling"};
static constexpr auto use_virtual_sd = std::string_view{"use_virtual_sd"};
static constexpr auto use_vsync = std::string_view{"use_vsync"};
static constexpr auto volume = std::string_view{"volume"};
}

} // namespace Settings

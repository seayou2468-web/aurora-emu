// Copyright 2018 Citra Emulator Project
// Licensed under GPLv2 or any later version
// Refer to the license.txt file included.

#include <algorithm>
#include <array>
#include <nlohmann/json.hpp>
#include <httplib.h>
#include "common/logging/log.h"
#include "web_service/verify_user_jwt.h"

namespace WebService {

namespace {
constexpr std::array<const char, 1> API_VERSION{'1'};
constexpr std::size_t TIMEOUT_SECONDS = 30;

Network::VerifyUser::UserData ParseUserData(const std::string& json_payload) {
    Network::VerifyUser::UserData user_data{};
    if (json_payload.empty()) {
        return user_data;
    }

    const auto json = nlohmann::json::parse(json_payload, nullptr, false);
    if (json.is_discarded()) {
        LOG_ERROR(WebService, "Failed to parse profile payload");
        return user_data;
    }

    if (json.contains("username") && json["username"].is_string()) {
        user_data.username = json["username"].get<std::string>();
    }
    if (json.contains("displayName") && json["displayName"].is_string()) {
        user_data.display_name = json["displayName"].get<std::string>();
    }
    if (json.contains("avatarUrl") && json["avatarUrl"].is_string()) {
        user_data.avatar_url = json["avatarUrl"].get<std::string>();
    }
    if (json.contains("roles") && json["roles"].is_array()) {
        for (const auto& role : json["roles"]) {
            if (role.is_string() && role.get<std::string>() == "moderator") {
                user_data.moderator = true;
                break;
            }
        }
    }
    return user_data;
}

} // namespace

VerifyUserJWT::VerifyUserJWT(const std::string& host) : host_url{host} {}

Network::VerifyUser::UserData VerifyUserJWT::LoadUserData(const std::string& verify_UID,
                                                          const std::string& token) {
    (void)verify_UID;
    if (host_url.empty() || token.empty()) {
        return {};
    }

    httplib::Client client(host_url.c_str());
    client.set_connection_timeout(TIMEOUT_SECONDS);
    client.set_read_timeout(TIMEOUT_SECONDS);
    client.set_write_timeout(TIMEOUT_SECONDS);

    if (!client.is_valid()) {
        LOG_ERROR(WebService, "Invalid URL {}", host_url);
        return {};
    }

    httplib::Headers headers{{std::string("Authorization"), fmt::format("Bearer {}", token)},
                             {std::string("api-version"),
                              std::string(API_VERSION.begin(), API_VERSION.end())}};
    auto response = client.Get("/profile", headers);
    if (!response || response->status >= 400) {
        LOG_INFO(WebService, "JWT profile request failed for host {}", host_url);
        return {};
    }

    return ParseUserData(response->body);
}

} // namespace WebService
